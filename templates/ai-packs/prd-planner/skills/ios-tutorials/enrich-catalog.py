#!/usr/bin/env python3
"""
enrich-catalog.py - Enrich tutorial catalog with better descriptions, tags, and keywords.

Phase 1: Static analysis of Swift source files (no API key needed)
Phase 2: Claude API for rich descriptions (requires ANTHROPIC_API_KEY)
Rebuild: Merge enrichments into catalog.json + tutorials-index.md

Usage:
    python3 enrich-catalog.py --static          # Phase 1 only
    python3 enrich-catalog.py --api             # Phase 2 only (needs API key)
    python3 enrich-catalog.py --all             # Both phases + rebuild
    python3 enrich-catalog.py --rebuild         # Rebuild catalog from cache
    python3 enrich-catalog.py --stats           # Show enrichment stats
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

# ── Paths ────────────────────────────────────────────────────────────────────

TUTORIALS_DIR = Path.home() / ".claude" / "tutorials"
CATALOG_FILE = TUTORIALS_DIR / "catalog.json"
INDEX_FILE = TUTORIALS_DIR / "tutorials-index.md"
CACHE_FILE = TUTORIALS_DIR / "enrichments-cache.json"
SKILL_DIR = Path.home() / ".claude" / "skills" / "ios-tutorials"

# ── API Detection Maps ───────────────────────────────────────────────────────

IMPORT_TO_TAGS = {
    "MapKit": ["map", "location"],
    "Charts": ["charts"],
    "PhotosUI": ["photos", "photo-picker"],
    "AVFoundation": ["video", "audio", "camera"],
    "AVKit": ["video", "media-player"],
    "CoreData": ["coredata"],
    "SwiftData": ["swiftdata"],
    "StoreKit": ["storekit", "iap"],
    "WidgetKit": ["widget"],
    "ActivityKit": ["live-activity"],
    "LocalAuthentication": ["biometrics", "auth"],
    "CoreLocation": ["location", "gps"],
    "CoreHaptics": ["haptics"],
    "Metal": ["metal", "shader", "gpu"],
    "SpriteKit": ["spritekit", "game"],
    "RealityKit": ["realitykit", "ar", "3d"],
    "ARKit": ["ar", "augmented-reality"],
    "Vision": ["vision", "ml", "image-recognition"],
    "CoreML": ["ml", "machine-learning"],
    "WebKit": ["webview"],
    "CoreImage": ["image-filter", "ci-filter"],
    "CoreGraphics": ["drawing", "core-graphics"],
    "PDFKit": ["pdf"],
    "Contacts": ["contacts"],
    "EventKit": ["calendar", "reminders"],
    "MessageUI": ["mail", "messages"],
    "SafariServices": ["safari", "browser"],
    "AuthenticationServices": ["auth", "sign-in"],
    "PassKit": ["wallet", "apple-pay"],
    "CoreMotion": ["motion", "accelerometer"],
    "CoreBluetooth": ["bluetooth"],
    "MultipeerConnectivity": ["peer-to-peer", "nearby"],
    "UserNotifications": ["notifications"],
    "BackgroundTasks": ["background"],
    "Combine": ["combine", "reactive"],
    "CloudKit": ["cloudkit", "sync"],
    "GameKit": ["gamekit", "game-center"],
    "ReplayKit": ["replay", "screen-recording"],
    "NaturalLanguage": ["nlp", "text-analysis"],
    "Speech": ["speech", "voice"],
    "CryptoKit": ["crypto", "encryption"],
    "NetworkExtension": ["vpn", "network"],
    "AppIntents": ["app-intents", "shortcuts", "siri"],
    "TipKit": ["tips", "onboarding"],
    "SwiftUI": ["swiftui"],
    "UIKit": ["uikit"],
}

# SwiftUI API patterns → tags + keywords
SWIFTUI_PATTERNS = {
    # Views & Containers
    r"\bCanvas\b": {"tags": ["canvas", "drawing"], "keywords": ["custom drawing", "2d graphics"]},
    r"\bTimelineView\b": {"tags": ["timeline", "real-time"], "keywords": ["live updates", "clock", "timer view"]},
    r"\bGeometryReader\b": {"tags": ["geometry"], "keywords": ["adaptive layout", "size-dependent"]},
    r"\bNavigationStack\b": {"tags": ["navigation"], "keywords": ["navigation stack", "push pop"]},
    r"\bNavigationSplitView\b": {"tags": ["navigation", "sidebar"], "keywords": ["split view", "sidebar navigation"]},
    r"\bTabView\b": {"tags": ["tabbar"], "keywords": ["tab bar", "paging"]},
    r"\.tabViewStyle\(.+page": {"tags": ["paging", "carousel"], "keywords": ["page view", "swipe pages"]},
    r"\bScrollView\b": {"tags": ["scroll"], "keywords": ["scrolling"]},
    r"\bLazyVGrid\b|\bLazyHGrid\b": {"tags": ["grid"], "keywords": ["grid layout", "collection"]},
    r"\bLazyVStack\b|\bLazyHStack\b": {"tags": ["lazy-loading"], "keywords": ["lazy stack"]},
    r"\bList\b": {"tags": ["list"], "keywords": ["list view"]},
    r"\bMap\b\s*\(|\bMap\s*\{": {"tags": ["map"], "keywords": ["map view", "mapkit"]},
    r"\bChart\b\s*\{": {"tags": ["charts"], "keywords": ["data visualization", "graph"]},
    r"\bVideoPlayer\b": {"tags": ["video"], "keywords": ["video playback"]},
    r"\bPhotoPicker\b|\bPhotosPicker\b": {"tags": ["photos", "photo-picker"], "keywords": ["image picker"]},
    r"\bTextEditor\b": {"tags": ["text-editor"], "keywords": ["multiline text", "rich text"]},
    r"\bTextField\b": {"tags": ["textfield"], "keywords": ["text input"]},
    r"\bSecureField\b": {"tags": ["textfield", "auth"], "keywords": ["password field"]},
    r"\bSearchable\b|\.searchable": {"tags": ["search"], "keywords": ["search bar"]},
    r"\bShareLink\b": {"tags": ["share"], "keywords": ["share sheet"]},

    # Modifiers & Effects
    r"\.blur\b": {"tags": ["blur"], "keywords": ["blur effect", "frosted"]},
    r"\.matchedGeometryEffect\b": {"tags": ["matched-geometry", "hero-animation"], "keywords": ["hero transition", "shared element"]},
    r"\.matchedTransitionSource\b": {"tags": ["hero-animation", "transition"], "keywords": ["hero transition", "zoom transition"]},
    r"\.navigationTransition\b": {"tags": ["hero-animation", "transition"], "keywords": ["navigation transition", "zoom"]},
    r"\.rotation3DEffect\b": {"tags": ["3d"], "keywords": ["3d rotation", "flip"]},
    r"\.scaleEffect\b": {"tags": ["animation"], "keywords": ["scale animation"]},
    r"\.mask\b": {"tags": ["mask"], "keywords": ["masking", "clipping"]},
    r"\.drawingGroup\b": {"tags": ["performance"], "keywords": ["gpu rendering"]},
    r"\.visualEffect\b": {"tags": ["visual-effect"], "keywords": ["scroll effect", "visual modifier"]},
    r"\.scrollTransition\b": {"tags": ["scroll-transition"], "keywords": ["scroll animation"]},
    r"\.containerRelativeFrame\b": {"tags": ["scroll"], "keywords": ["paging scroll"]},
    r"\.sensoryFeedback\b": {"tags": ["haptics"], "keywords": ["haptic feedback"]},
    r"\.sheet\b": {"tags": ["sheet"], "keywords": ["modal sheet", "bottom sheet"]},
    r"\.fullScreenCover\b": {"tags": ["modal"], "keywords": ["fullscreen modal"]},
    r"\.popover\b": {"tags": ["popover"], "keywords": ["popover menu"]},
    r"\.confirmationDialog\b": {"tags": ["dialog"], "keywords": ["action sheet"]},
    r"\.alert\b": {"tags": ["alert"], "keywords": ["alert dialog"]},
    r"\.toolbar\b": {"tags": ["toolbar"], "keywords": ["toolbar"]},
    r"\.inspector\b": {"tags": ["inspector"], "keywords": ["side panel"]},
    r"\.overlay\b": {"tags": ["overlay"], "keywords": ["overlay layer"]},
    r"\.background\b": {"tags": [], "keywords": []},
    r"\.clipShape\b": {"tags": ["custom-shape"], "keywords": ["clipped shape"]},
    r"\.contentTransition\b": {"tags": ["transition"], "keywords": ["content transition"]},
    r"\.transition\b": {"tags": ["transition"], "keywords": ["view transition"]},
    r"\.symbolEffect\b": {"tags": ["sf-symbols"], "keywords": ["symbol animation"]},
    r"\.phaseAnimator\b": {"tags": ["phase-animation"], "keywords": ["multi-phase animation"]},
    r"\.keyframeAnimator\b": {"tags": ["keyframe"], "keywords": ["keyframe animation"]},
    r"\.scrollPosition\b|\.scrollTargetLayout\b": {"tags": ["scroll-tracking"], "keywords": ["scroll position", "snap scroll"]},
    r"\.onScrollGeometryChange\b": {"tags": ["scroll-tracking"], "keywords": ["scroll geometry"]},
    r"\.safeAreaInset\b": {"tags": ["safe-area"], "keywords": ["safe area overlay"]},
    r"\.interactiveDismissDisabled\b": {"tags": ["sheet"], "keywords": ["undismissable sheet"]},
    r"\.presentationDetents\b": {"tags": ["bottom-sheet"], "keywords": ["sheet detents", "half sheet"]},
    r"\.presentationDragIndicator\b": {"tags": ["bottom-sheet"], "keywords": ["drag indicator"]},
    r"\.swipeActions\b": {"tags": ["swipe-actions"], "keywords": ["swipe to delete", "swipe action"]},
    r"\.refreshable\b": {"tags": ["pull-to-refresh"], "keywords": ["pull to refresh"]},
    r"\.onDrag\b|\.onDrop\b|\.draggable\b|\.dropDestination\b": {"tags": ["drag-drop"], "keywords": ["drag and drop"]},
    r"\.contextMenu\b": {"tags": ["context-menu"], "keywords": ["long press menu"]},
    r"\.fileImporter\b|\.fileExporter\b": {"tags": ["files"], "keywords": ["file picker"]},
    r"\.handlesExternalEvents\b|\.onOpenURL\b": {"tags": ["deep-link"], "keywords": ["deep linking", "url scheme"]},

    # Gestures
    r"\bDragGesture\b": {"tags": ["drag", "gesture"], "keywords": ["drag gesture", "swipe"]},
    r"\bMagnification\b|\bMagnifyGesture\b": {"tags": ["pinch", "gesture"], "keywords": ["pinch zoom"]},
    r"\bRotat(ion|e)Gesture\b": {"tags": ["rotation", "gesture"], "keywords": ["rotate gesture"]},
    r"\bLongPressGesture\b": {"tags": ["long-press", "gesture"], "keywords": ["long press"]},
    r"\bSpatialTapGesture\b": {"tags": ["gesture"], "keywords": ["spatial tap"]},

    # Shapes & Paths
    r"\bPath\b\s*\{|\bUIBezierPath\b": {"tags": ["custom-shape", "drawing"], "keywords": ["custom path", "bezier"]},
    r"\bShape\b.*protocol|struct.*:\s*Shape\b": {"tags": ["custom-shape"], "keywords": ["custom shape"]},

    # Animation
    r"\bAnimatableData\b|AnimatableModifier\b": {"tags": ["custom-animation"], "keywords": ["animatable", "custom animation"]},
    r"\bPreferenceKey\b": {"tags": ["preference-key"], "keywords": ["child-to-parent data"]},
    r"\bViewModifier\b": {"tags": ["custom-modifier"], "keywords": ["view modifier"]},
    r"\.spring\b": {"tags": ["spring-animation"], "keywords": ["spring physics"]},
    r"\.interpolatingSpring\b": {"tags": ["spring-animation"], "keywords": ["spring bounce"]},
    r"withAnimation\b": {"tags": ["animation"], "keywords": ["animated"]},

    # UIKit bridging
    r"\bUIViewRepresentable\b": {"tags": ["uikit-bridge"], "keywords": ["uikit in swiftui"]},
    r"\bUIViewControllerRepresentable\b": {"tags": ["uikit-bridge"], "keywords": ["viewcontroller bridge"]},
    r"\bUIHostingController\b": {"tags": ["uikit-bridge"], "keywords": ["swiftui in uikit"]},
    r"\bCATransform3D\b": {"tags": ["3d", "uikit"], "keywords": ["3d transform", "perspective"]},
    r"\bCADisplayLink\b": {"tags": ["display-link"], "keywords": ["frame callback", "render loop"]},
    r"\bCAEmitterLayer\b": {"tags": ["particles"], "keywords": ["particle emitter"]},
    r"\bCAShapeLayer\b": {"tags": ["drawing"], "keywords": ["shape layer"]},
    r"\bCAGradientLayer\b": {"tags": ["gradient"], "keywords": ["gradient layer"]},
    r"\bCABasicAnimation\b|CAKeyframeAnimation\b": {"tags": ["core-animation"], "keywords": ["ca animation"]},
    r"\bUIScrollView\b": {"tags": ["scroll", "uikit"], "keywords": ["scroll view uikit"]},
    r"\bUICollectionView\b": {"tags": ["collection", "uikit"], "keywords": ["collection view"]},
    r"\bMKMapView\b": {"tags": ["map", "uikit"], "keywords": ["map view uikit"]},

    # Shader / Metal in SwiftUI
    r"\.layerEffect\b|\.colorEffect\b|\.distortionEffect\b": {"tags": ["shader", "metal"], "keywords": ["shader effect", "metal shader"]},
    r"\bShaderLibrary\b": {"tags": ["shader", "metal"], "keywords": ["custom shader"]},

    # Data
    r"@Query\b": {"tags": ["swiftdata"], "keywords": ["swiftdata query"]},
    r"@FetchRequest\b": {"tags": ["coredata"], "keywords": ["core data fetch"]},
    r"\.modelContainer\b": {"tags": ["swiftdata"], "keywords": ["model container"]},
    r"@AppStorage\b": {"tags": ["persistence"], "keywords": ["user defaults"]},

    # Liquid Glass / iOS 26
    r"\.glassEffect\b|\.liquidGlass\b": {"tags": ["liquid-glass", "ios26"], "keywords": ["liquid glass", "frosted glass"]},
}

# Name-based keyword expansion for common UI patterns
NAME_KEYWORDS = {
    "metaball": ["blob", "liquid merge", "organic shapes", "fluid animation"],
    "parallax": ["depth effect", "scroll depth", "layered scroll"],
    "glassmorphism": ["glass effect", "frosted glass", "translucent", "blur background"],
    "shimmer": ["skeleton loading", "placeholder animation", "loading shimmer"],
    "skeleton": ["loading placeholder", "shimmer", "content loading"],
    "toast": ["notification popup", "snackbar", "alert banner", "floating message"],
    "carousel": ["horizontal scroll", "card slider", "paging cards"],
    "coverflow": ["cover flow", "album scroll", "3d carousel"],
    "onboarding": ["welcome screen", "intro tutorial", "first launch", "walkthrough"],
    "splash": ["splash screen", "launch animation", "app intro"],
    "paywall": ["subscription screen", "pricing", "in-app purchase ui"],
    "login": ["sign in", "authentication", "credentials", "sign up"],
    "chat": ["messaging", "conversation", "chat bubbles"],
    "bottom": ["bottom sheet", "drawer", "pull up panel"],
    "sidebar": ["side menu", "hamburger", "drawer menu"],
    "dropdown": ["expandable", "collapsible", "accordion"],
    "tooltip": ["hint", "info bubble", "floating label"],
    "progress": ["loading bar", "step indicator", "progress ring"],
    "wheel": ["picker wheel", "scroll picker", "spinning selector"],
    "confetti": ["celebration", "party effect", "success animation"],
    "ripple": ["touch effect", "tap feedback", "material ripple"],
    "morphing": ["shape morph", "transform", "interpolation"],
    "sticky": ["sticky header", "pinned header", "floating header"],
    "expandable": ["collapsible", "accordion", "expand collapse"],
    "swipe": ["swipe action", "sliding", "gesture card"],
    "drag": ["draggable", "reorder", "move"],
    "flip": ["card flip", "3d flip", "front back"],
    "zoom": ["pinch zoom", "magnify", "scale"],
    "wave": ["wave animation", "water effect", "sine wave"],
    "gradient": ["color gradient", "gradient background", "color blend"],
    "blur": ["gaussian blur", "frosted", "backdrop blur"],
    "glow": ["neon glow", "light effect", "radiance"],
    "pulse": ["pulsing", "heartbeat", "breathing animation"],
    "bounce": ["bouncy", "spring", "elastic"],
    "slide": ["sliding", "slide in", "slide animation"],
    "fade": ["fade in", "fade out", "opacity animation"],
    "rotate": ["rotation", "spinning", "circular motion"],
    "particle": ["particles", "emitter", "sparkle"],
    "mask": ["masking", "reveal", "clip mask"],
    "timer": ["countdown", "stopwatch", "clock"],
    "clock": ["time display", "analog clock", "digital clock"],
    "calendar": ["date picker", "schedule", "events"],
    "weather": ["weather ui", "forecast", "climate"],
    "music": ["audio player", "now playing", "playlist"],
    "photo": ["image gallery", "photo grid", "picture viewer"],
    "video": ["video player", "media player", "streaming"],
    "map": ["mapkit", "location", "pin annotation", "directions"],
    "chart": ["graph", "data visualization", "bar chart", "line chart"],
    "settings": ["preferences", "configuration", "options screen"],
    "profile": ["user profile", "account", "avatar"],
    "wallet": ["card wallet", "apple wallet", "credit card"],
    "header": ["navigation header", "top bar", "header animation"],
    "tabbar": ["tab bar", "bottom navigation", "tab icons"],
    "segmented": ["segmented control", "filter tabs", "toggle tabs"],
    "picker": ["selection", "chooser", "option picker"],
    "slider": ["range slider", "scrubber", "volume control"],
    "toggle": ["switch", "on off", "boolean control"],
    "badge": ["notification badge", "count badge", "indicator dot"],
    "tag": ["tag chip", "label chip", "filter tag"],
    "chip": ["chip selection", "filter chip", "tag chip"],
    "avatar": ["user icon", "profile picture", "initials"],
    "breadcrumb": ["path indicator", "navigation path"],
    "stepper": ["step indicator", "wizard", "multi-step"],
    "otp": ["verification code", "pin code", "one time password"],
    "pin": ["pin entry", "passcode", "lock screen"],
    "keypad": ["number pad", "numeric keyboard", "dial pad"],
    "hero": ["hero animation", "shared element", "detail transition"],
    "detail": ["detail view", "item detail", "expanded view"],
    "grid": ["grid layout", "masonry", "tiles"],
    "waterfall": ["masonry layout", "pinterest grid", "staggered grid"],
    "snap": ["snap scroll", "paging", "card snap"],
    "infinite": ["infinite scroll", "pagination", "load more"],
    "pull": ["pull to refresh", "pull down", "pull up"],
    "floating": ["floating button", "fab", "floating action"],
    "dock": ["dock bar", "floating bar", "action dock"],
    "apple": ["apple style", "ios native", "system design"],
    "material": ["material design", "android style"],
    "neumorphism": ["soft ui", "embossed", "inset shadow"],
    "skeuomorphism": ["realistic", "textured", "3d realistic"],
    "minimal": ["minimalist", "clean", "simple"],
    "dark": ["dark mode", "dark theme", "night mode"],
    "liquid": ["fluid", "water", "organic movement"],
    "elastic": ["rubber", "stretch", "deform"],
    "magnetic": ["magnet effect", "snap to edge", "attract"],
    "radial": ["radial menu", "circular layout", "pie"],
    "circular": ["circle layout", "round", "ring"],
    "ring": ["circular progress", "donut", "ring chart"],
    "stack": ["card stack", "stacked cards", "deck"],
    "tinder": ["swipe cards", "card deck", "match cards"],
    "stories": ["instagram stories", "story carousel", "story ring"],
    "reels": ["vertical video", "short video", "tiktok"],
    "instagram": ["social feed", "photo grid", "stories"],
    "twitter": ["tweet", "social post", "feed"],
    "spotify": ["music app", "playlist ui", "now playing"],
    "uber": ["ride ui", "map trip", "destination picker"],
    "airbnb": ["listing card", "booking", "property"],
    "netflix": ["movie card", "streaming ui", "content row"],
}


def load_cache():
    if CACHE_FILE.exists():
        return json.loads(CACHE_FILE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache):
    CACHE_FILE.write_text(
        json.dumps(cache, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )


def load_catalog():
    if CATALOG_FILE.exists():
        return json.loads(CATALOG_FILE.read_text(encoding="utf-8"))
    return {"version": 1, "tutorials": []}


def get_swift_files(tutorial_path):
    """Get all Swift file paths for a tutorial."""
    project_dir = TUTORIALS_DIR / tutorial_path / "project"
    if not project_dir.exists():
        return []
    swift_files = []
    for root, _, files in os.walk(project_dir):
        # Skip build/derived data directories
        if any(skip in root for skip in [".build", "DerivedData", ".swiftpm", "Pods"]):
            continue
        for f in files:
            if f.endswith(".swift"):
                swift_files.append(os.path.join(root, f))
    return swift_files


def read_swift_content(tutorial_path, max_chars=50000):
    """Read concatenated Swift content for a tutorial, prioritizing non-App files."""
    files = get_swift_files(tutorial_path)
    if not files:
        return ""

    # Sort: non-App files first (they have the interesting code), then App files
    def priority(f):
        name = os.path.basename(f).lower()
        if "app.swift" in name:
            return 2
        if "contentview" in name:
            return 1
        return 0

    files.sort(key=priority)

    content = []
    total = 0
    for f in files:
        try:
            text = Path(f).read_text(encoding="utf-8", errors="ignore")
            # Strip comments to save space
            text = re.sub(r"//.*$", "", text, flags=re.MULTILINE)
            text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
            content.append(f"// FILE: {os.path.basename(f)}\n{text}")
            total += len(text)
            if total > max_chars:
                break
        except Exception:
            continue
    return "\n".join(content)


def extract_view_names(content):
    """Extract SwiftUI View struct names."""
    return re.findall(r"struct\s+(\w+)\s*:\s*(?:\w+,\s*)*View\b", content)


def analyze_tutorial_static(tutorial_name, tutorial_path):
    """Phase 1: Static analysis of a single tutorial."""
    content = read_swift_content(tutorial_path)
    if not content:
        return {"tags": [], "keywords": [], "apis": [], "views": [], "description": ""}

    tags = set()
    keywords = set()
    apis = set()

    # 1. Import analysis
    imports = re.findall(r"^import\s+(\w+)", content, re.MULTILINE)
    for imp in imports:
        if imp in IMPORT_TO_TAGS:
            for t in IMPORT_TO_TAGS[imp]:
                tags.add(t)

    # 2. SwiftUI pattern detection
    for pattern, data in SWIFTUI_PATTERNS.items():
        if re.search(pattern, content):
            for t in data["tags"]:
                tags.add(t)
            for k in data["keywords"]:
                keywords.add(k)
            # Extract the API name for reference
            api_name = pattern.replace(r"\b", "").replace(r"\.", ".").replace("\\", "")
            apis.add(api_name.split("|")[0].split("(")[0].strip())

    # 3. Name-based keyword expansion
    name_lower = tutorial_name.lower().replace("-", " ").replace("_", " ")
    for key, kws in NAME_KEYWORDS.items():
        if key in name_lower:
            for kw in kws:
                keywords.add(kw)
            tags.add(key)

    # 4. Extract view names
    views = extract_view_names(content)

    # 5. Detect specific high-value patterns via ast-grep if available
    # (Fallback to regex if ast-grep not found)
    try:
        # Check for custom Shape conformances
        shapes = re.findall(r"struct\s+(\w+)\s*:\s*Shape\b", content)
        if shapes:
            tags.add("custom-shape")
            keywords.add("custom shape: " + ", ".join(shapes[:3]))

        # Check for ViewModifier conformances
        modifiers = re.findall(r"struct\s+(\w+)\s*:\s*ViewModifier\b", content)
        if modifiers:
            tags.add("custom-modifier")

        # Check for PreferenceKey
        pref_keys = re.findall(r"struct\s+(\w+)\s*:\s*PreferenceKey\b", content)
        if pref_keys:
            tags.add("preference-key")

        # Check for @Observable / ObservableObject
        if re.search(r"@Observable\b", content):
            tags.add("observable")
        if re.search(r"ObservableObject\b", content):
            tags.add("observable-object")

        # Check for environment usage
        if re.search(r"@Environment\b", content):
            tags.add("environment")

    except Exception:
        pass

    return {
        "tags": sorted(tags),
        "keywords": sorted(keywords),
        "apis": sorted(apis)[:20],
        "views": views[:10],
        "description": "",  # Will be filled by Phase 2
    }


def run_phase1():
    """Phase 1: Static analysis on all tutorials."""
    catalog = load_catalog()
    cache = load_cache()

    tutorials = catalog.get("tutorials", [])
    total = len(tutorials)
    enriched = 0
    skipped = 0

    print(f"Phase 1: Analyzing {total} tutorials...")

    for i, tut in enumerate(tutorials):
        name = tut["name"]
        path = tut.get("path", name)

        # Skip if already cached with static analysis
        if name in cache and cache[name].get("static_done"):
            skipped += 1
            continue

        result = analyze_tutorial_static(name, path)

        # Merge with existing cache entry
        entry = cache.get(name, {})
        entry["static_done"] = True
        entry["static_tags"] = result["tags"]
        entry["static_keywords"] = result["keywords"]
        entry["apis"] = result["apis"]
        entry["views"] = result["views"]
        # Don't overwrite API description if it exists
        if not entry.get("api_description"):
            entry["api_description"] = ""

        cache[name] = entry
        enriched += 1

        if (i + 1) % 50 == 0:
            print(f"  Progress: {i+1}/{total} ({enriched} enriched, {skipped} cached)")
            save_cache(cache)

    save_cache(cache)
    print(f"Phase 1 complete: {enriched} enriched, {skipped} cached, {total} total")

    # Stats
    all_tags = Counter()
    all_keywords = Counter()
    for entry in cache.values():
        for t in entry.get("static_tags", []):
            all_tags[t] += 1
        for k in entry.get("static_keywords", []):
            all_keywords[k] += 1

    print(f"\nUnique tags detected: {len(all_tags)}")
    print(f"Unique keywords detected: {len(all_keywords)}")
    print(f"Top 20 tags: {all_tags.most_common(20)}")


def get_generic_tutorials(cache, catalog):
    """Find tutorials that still have generic/empty descriptions."""
    generic_phrases = [
        "Implementación de ContentView en SwiftUI",
        "Componente o animación en SwiftUI",
    ]
    result = []
    for tut in catalog.get("tutorials", []):
        name = tut["name"]
        desc = tut.get("description", "")
        cached = cache.get(name, {})

        # Already has API-generated description
        if cached.get("api_description"):
            continue

        # Has a real description in catalog
        is_generic = not desc or any(g in desc for g in generic_phrases)
        if is_generic:
            result.append(tut)

    return result


def build_api_prompt(tutorials_batch, cache):
    """Build a prompt for Claude API to describe a batch of tutorials."""
    items = []
    for tut in tutorials_batch:
        name = tut["name"]
        cached = cache.get(name, {})
        # Read a compact version of the code (just key views, 2000 chars max per tutorial)
        content = read_swift_content(tut.get("path", name), max_chars=3000)
        if not content:
            content = "(no source code available)"

        # Truncate to essential parts
        if len(content) > 3000:
            content = content[:3000] + "\n... (truncated)"

        apis = cached.get("apis", [])
        views = cached.get("views", [])

        items.append(
            f"### {name}\n"
            f"Views: {', '.join(views) if views else 'unknown'}\n"
            f"APIs detected: {', '.join(apis[:10]) if apis else 'none'}\n"
            f"```swift\n{content}\n```"
        )

    prompt = (
        "You are analyzing SwiftUI tutorial projects. For each tutorial below, provide:\n"
        "1. A **description** (1-2 sentences in Spanish) of what the tutorial creates visually — "
        "describe the UI pattern/effect, not the code. Be specific about the visual result.\n"
        "2. **keywords** — 3-5 Spanish+English search terms a developer might use to find this pattern.\n\n"
        "Respond ONLY with valid JSON array. Each element:\n"
        '{"name": "tutorial-name", "description": "...", "keywords": ["...", "..."]}\n\n'
        "IMPORTANT: Descriptions should help developers FIND this tutorial by searching. "
        "Be specific about the visual effect, not generic.\n\n"
        + "\n\n".join(items)
    )
    return prompt


def run_phase2(batch_size=8, max_batches=None):
    """Phase 2: Claude Code CLI enrichment for tutorials with generic descriptions.

    Uses `claude -p` (print mode) which leverages the user's existing Claude Code
    subscription — no separate API key needed.
    """
    # Verify claude CLI is available
    claude_path = subprocess.run(
        ["which", "claude"], capture_output=True, text=True
    ).stdout.strip()
    if not claude_path:
        print("Error: claude CLI not found. Install Claude Code first.")
        sys.exit(1)
    print(f"Using Claude Code CLI at: {claude_path}")

    catalog = load_catalog()
    cache = load_cache()

    generic = get_generic_tutorials(cache, catalog)
    total = len(generic)
    print(f"Phase 2: {total} tutorials need CLI enrichment")

    if total == 0:
        print("All tutorials already have descriptions!")
        return

    batches = [generic[i : i + batch_size] for i in range(0, total, batch_size)]
    if max_batches:
        batches = batches[:max_batches]

    processed = 0
    errors = 0

    for bi, batch in enumerate(batches):
        print(f"  Batch {bi+1}/{len(batches)} ({len(batch)} tutorials)...")

        prompt = build_api_prompt(batch, cache)

        try:
            # Use claude -p (print mode) with haiku for speed/cost
            result = subprocess.run(
                ["claude", "-p", "--model", "haiku", "--output-format", "text"],
                input=prompt,
                capture_output=True,
                text=True,
                timeout=120,
            )

            if result.returncode != 0:
                print(f"    CLI error (code {result.returncode}): {result.stderr[:200]}")
                errors += 1
                continue

            text = result.stdout.strip()
            # Strip markdown code fences if present
            text = re.sub(r"^```(?:json)?\s*\n?", "", text)
            text = re.sub(r"\n?```\s*$", "", text)
            text = text.strip()
            # Extract JSON array from response
            json_match = re.search(r"\[.*\]", text, re.DOTALL)
            if json_match:
                results = json.loads(json_match.group())
            else:
                results = json.loads(text)

            for item in results:
                name = item.get("name", "")
                if name in cache:
                    cache[name]["api_description"] = item.get("description", "")
                    api_kws = item.get("keywords", [])
                    existing_kws = set(cache[name].get("static_keywords", []))
                    existing_kws.update(api_kws)
                    cache[name]["api_keywords"] = sorted(existing_kws)
                    processed += 1

        except subprocess.TimeoutExpired:
            print(f"    Timeout on batch {bi+1}")
            errors += 1
        except json.JSONDecodeError as e:
            print(f"    JSON parse error: {e}")
            # Save raw output for debugging
            debug_file = TUTORIALS_DIR / f"debug-batch-{bi+1}.txt"
            debug_file.write_text(text, encoding="utf-8")
            print(f"    Raw output saved to: {debug_file}")
            errors += 1
        except Exception as e:
            print(f"    Error: {e}")
            errors += 1

        save_cache(cache)

        # Small pause between batches
        if bi < len(batches) - 1:
            time.sleep(1)

    print(f"Phase 2 complete: {processed} enriched, {errors} errors")


def rebuild_catalog():
    """Rebuild catalog.json and tutorials-index.md from frontmatter + enrichments."""
    catalog = load_catalog()
    cache = load_cache()

    generic_phrases = [
        "Implementación de ContentView en SwiftUI.",
        "Componente o animación en SwiftUI.",
    ]

    enriched_count = 0
    tutorials = catalog.get("tutorials", [])

    for tut in tutorials:
        name = tut["name"]
        cached = cache.get(name, {})

        # Merge description
        if cached.get("api_description"):
            tut["description"] = cached["api_description"]
            enriched_count += 1
        elif tut.get("description", "") in generic_phrases:
            # Keep original if no better one available
            pass

        # Merge tags (original + static)
        original_tags = set(tut.get("tags", []))
        static_tags = set(cached.get("static_tags", []))
        merged_tags = sorted(original_tags | static_tags)
        tut["tags"] = merged_tags

        # Add keywords field
        all_keywords = set(cached.get("static_keywords", []))
        all_keywords.update(cached.get("api_keywords", []))
        if all_keywords:
            tut["keywords"] = sorted(all_keywords)

        # Add apis field (compact)
        if cached.get("apis"):
            tut["apis"] = cached["apis"][:10]

        # Add views field
        if cached.get("views"):
            tut["views"] = cached["views"][:5]

    # Update catalog metadata
    catalog["version"] = 2
    catalog["generated"] = datetime.now(timezone.utc).isoformat()
    catalog["enriched"] = enriched_count

    CATALOG_FILE.write_text(
        json.dumps(catalog, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    print(f"Catalog rebuilt: {len(tutorials)} tutorials, {enriched_count} with API descriptions")

    # Rebuild tutorials-index.md
    rebuild_index(catalog)


def rebuild_index(catalog):
    """Rebuild tutorials-index.md from enriched catalog."""
    tutorials = catalog.get("tutorials", [])

    # Group by category
    categories = {}
    category_tags = {
        "Animaciones y transiciones": {"animation", "transition", "matched-geometry", "hero-animation", "spring-animation", "phase-animation", "keyframe", "custom-animation"},
        "Scroll y paginacion": {"scroll", "scroll-transition", "scroll-tracking", "parallax", "paging", "carousel", "infinite-scroll", "pull-to-refresh", "lazy-loading", "snap"},
        "Navegacion y tab bars": {"navigation", "tabbar", "sidebar", "deep-link"},
        "Formularios y entrada": {"textfield", "picker", "slider", "toggle", "search", "otp", "text-editor"},
        "Modales y overlays": {"sheet", "bottom-sheet", "modal", "popover", "overlay", "toast", "alert", "dialog", "drawer", "context-menu"},
        "Listas y grids": {"list", "grid", "collection", "swipe-actions", "drag-drop"},
        "Mapas y ubicacion": {"map", "location", "gps"},
        "Graficos y datos": {"charts", "data-visualization"},
        "Media y camara": {"video", "audio", "camera", "photos", "photo-picker", "media-player"},
        "Efectos visuales": {"blur", "glassmorphism", "liquid-glass", "gradient", "shader", "metal", "mask", "custom-shape", "particles", "drawing", "canvas", "visual-effect", "sf-symbols"},
        "Login y autenticacion": {"login", "auth", "biometrics", "sign-in"},
        "Datos y persistencia": {"swiftdata", "coredata", "persistence", "cloudkit"},
        "Widgets y extensiones": {"widget", "live-activity"},
        "Otros patrones UI": set(),  # catch-all
    }

    # Initialize categories
    for cat in category_tags:
        categories[cat] = []

    for tut in tutorials:
        tut_tags = set(tut.get("tags", []))
        placed = False
        for cat, cat_tag_set in category_tags.items():
            if cat == "Otros patrones UI":
                continue
            if tut_tags & cat_tag_set:
                categories[cat].append(tut)
                placed = True
        if not placed:
            categories["Otros patrones UI"].append(tut)

    # Build markdown
    lines = [
        "# Tutorials Index -- SwiftUI SwiftUI",
        "",
        "> Indice categorizado de tutoriales SwiftUI para SwiftUI.",
        "> Generado automaticamente por enrich-catalog.py. No editar manualmente.",
        "",
        "## Instrucciones para agentes",
        "",
        "- Lee solo la seccion de la categoria relevante, no el fichero completo.",
        "- Usa el path de SKILL.md para cargar el tutorial que necesites.",
        "- Un tutorial puede aparecer en multiples categorias si sus tags lo justifican.",
        "- **NUEVO**: Busca tambien por el campo `keywords` para encontrar tutoriales por sinonimos.",
        "",
    ]

    total_entries = sum(len(v) for v in categories.values())
    lines.append(f"**Total de tutoriales:** {len(tutorials)}  ")
    lines.append(f"**Categorias:** {len(categories)}  ")
    lines.append(f"**Entradas totales (con duplicados entre categorias):** {total_entries}")
    lines.append("")
    lines.append("---")
    lines.append("")

    for cat, tuts in categories.items():
        lines.append(f"## {cat} ({len(tuts)})")
        lines.append("")
        for tut in sorted(tuts, key=lambda t: t["name"]):
            desc = tut.get("description", "")
            if len(desc) > 120:
                desc = desc[:117] + "..."
            ios = tut.get("min_ios", "")
            platform = tut.get("platform", "ios")
            tags = ", ".join(tut.get("tags", []))
            keywords = ", ".join(tut.get("keywords", [])[:5]) if tut.get("keywords") else ""
            path = f"`~/.claude/tutorials/{tut['path']}/SKILL.md`"

            entry = f"- **{tut['name']}** -- {desc} | {ios} | {platform} | tags: {tags}"
            if keywords:
                entry += f" | keywords: {keywords}"
            entry += f" | {path}"
            lines.append(entry)
        lines.append("")

    INDEX_FILE.write_text("\n".join(lines), encoding="utf-8")
    print(f"Index rebuilt: {len(categories)} categories, {total_entries} entries")


def show_stats():
    """Show enrichment statistics."""
    cache = load_cache()
    catalog = load_catalog()

    total = len(catalog.get("tutorials", []))
    cached = len(cache)
    static_done = sum(1 for v in cache.values() if v.get("static_done"))
    has_api_desc = sum(1 for v in cache.values() if v.get("api_description"))
    has_keywords = sum(1 for v in cache.values() if v.get("static_keywords"))

    generic = get_generic_tutorials(cache, catalog)

    print(f"=== Enrichment Stats ===")
    print(f"Total tutorials:      {total}")
    print(f"Cached entries:       {cached}")
    print(f"Static analysis done: {static_done}")
    print(f"API descriptions:     {has_api_desc}")
    print(f"With keywords:        {has_keywords}")
    print(f"Still generic:        {len(generic)}")
    print()

    # Tag distribution
    all_tags = Counter()
    for tut in catalog.get("tutorials", []):
        name = tut["name"]
        original = set(tut.get("tags", []))
        enriched = set(cache.get(name, {}).get("static_tags", []))
        for t in original | enriched:
            all_tags[t] += 1

    print(f"Total unique tags: {len(all_tags)}")
    print("Top 30 tags:")
    for tag, count in all_tags.most_common(30):
        print(f"  {tag}: {count}")


def main():
    parser = argparse.ArgumentParser(description="Enrich tutorial catalog")
    parser.add_argument("--static", action="store_true", help="Run Phase 1: static analysis")
    parser.add_argument("--api", action="store_true", help="Run Phase 2: Claude API enrichment")
    parser.add_argument("--all", action="store_true", help="Run all phases + rebuild")
    parser.add_argument("--rebuild", action="store_true", help="Rebuild catalog from cache")
    parser.add_argument("--stats", action="store_true", help="Show enrichment stats")
    parser.add_argument("--batch-size", type=int, default=8, help="Tutorials per API batch")
    parser.add_argument("--max-batches", type=int, default=None, help="Max API batches (for testing)")

    args = parser.parse_args()

    if not any([args.static, args.api, args.all, args.rebuild, args.stats]):
        parser.print_help()
        sys.exit(0)

    if args.stats:
        show_stats()
        return

    if args.static or args.all:
        run_phase1()

    if args.api or args.all:
        run_phase2(batch_size=args.batch_size, max_batches=args.max_batches)

    if args.rebuild or args.all:
        rebuild_catalog()


if __name__ == "__main__":
    main()
