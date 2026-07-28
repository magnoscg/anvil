---
name: ios-tutorials
description: >
  MANDATORY pre-implementation reference for ANY iOS/SwiftUI UI work.
  Before writing ANY SwiftUI view, animation, layout, or visual component,
  Claude MUST search your local tutorial library for reference implementations.
  Proactively invoke before UI implementation — do not wait for /ios-tutorials command.
  Covers: carousels, tab bars, headers, sheets, glassmorphism, parallax, cards, grids,
  charts, scroll effects, animations, navigation patterns, and 50+ more UI patterns.
---

# iOS Tutorials Router

## PROACTIVE INVOCATION RULE

**You MUST invoke this skill BEFORE implementing ANY iOS/SwiftUI UI component.**

This is NOT just a search tool the user types. This is a mandatory reference check that Claude
performs automatically whenever the task involves:
- Creating or modifying a SwiftUI view
- Implementing any animation, transition, or gesture
- Building navigation patterns (tab bars, sidebars, headers)
- Creating scroll effects (parallax, sticky headers, carousels)
- Implementing any visual pattern (cards, sheets, glassmorphism, blur)
- Building any list, grid, or collection layout
- Designing onboarding, login, or splash screens

### How to Proactively Search

When you identify that UI work is needed:
1. Extract 2-3 keyword terms from the requirement (e.g., "parallax header", "tab bar animation")
2. **Multi-field search** in `~/.claude/tutorials/catalog.json` using Grep — search for EACH term separately:
   - First grep for the term — it will match across name, tags, description, AND keywords fields
   - If few results, try synonyms (e.g., "blob" if "metaball" fails, "bottom sheet" if "drawer" fails)
3. If results found, present the top 3 matches and ask which to load
4. Read the SKILL.md of matching tutorials for implementation patterns
5. **Read source code** from `~/.claude/tutorials/<name>/project/` — the SKILL.md may be sparse but source files are always complete
6. If no match, proceed with Axiom guidelines

**Search tip**: The catalog now includes `keywords` with synonyms and aliases. If your first search term finds nothing, check the keywords field — e.g., searching "liquid merge" will find "metaball" via keywords.

### Anti-Rationalization

| Thought | Reality |
|---------|---------|
| "I know how to build this SwiftUI view" | Your tutorial library may already have a battle-tested implementation. Check first. |
| "This is too simple for a tutorial lookup" | Simple patterns often have SwiftUI refinements you'd miss. |
| "The user didn't ask me to search tutorials" | CLAUDE.md says "antes de implementar UI, consulta tutoriales". This is mandatory. |
| "Axiom already gave me the patterns" | Axiom gives guidelines. SwiftUI gives copy-paste implementations. Both are needed. |
| "I'll search if I get stuck" | Search BEFORE you start, not after you're stuck. Prevention > cure. |

---

Search and retrieve iOS/SwiftUI tutorials from your own curated local library.

## How to Search

When this skill is invoked, follow these steps:

### Step 1: Search the Catalog

There are two search sources depending on the query:

**A) Category search (tutorials-index.md):**
If the user specifies `category:<name>`, search `~/.claude/tutorials/tutorials-index.md` for that category section instead of catalog.json. This is faster for browsing by topic.

Example:
```
/ios-tutorials category:headers
→ Read ~/.claude/tutorials/tutorials-index.md, find the "headers" section
```

**B) Keyword search (catalog.json):**
For all other queries, use Grep to search `~/.claude/tutorials/catalog.json` for the user's query terms.

Search against these fields (priority order):
1. **tags** — exact tag match is strongest signal
2. **keywords** — synonym/alias match (e.g., "blob" finds metaball, "skeleton loading" finds shimmer)
3. **name** — substring match in the skill name
4. **description** — keyword match in rich description (visual effect described in Spanish)

**Filters:**
- **iOS version** (`ios:<version>`): filter by `min_ios <= <version>`. Example: `/ios-tutorials carousel ios:18` shows tutorials compatible with iOS 18.
- **Platform** (`platform:<platform>`): filter by `platform` field. Example: `/ios-tutorials tabbar platform:ipad` shows iPad-compatible tutorials.
- If no explicit filter syntax is used but the user mentions iOS or platform in natural language, apply the same filtering.

Example:
```
Grep pattern: "carousel" in ~/.claude/tutorials/catalog.json
```

### Step 2: Present Results

Show the user a table of matching tutorials (max 10 results):

| # | Name | Description | iOS | Tags |
|---|------|-------------|-----|------|
| 1 | ... | ... | ... | ... |

Ask which one(s) to load.

### Step 3: Load Selected Tutorial

Read the full SKILL.md for the selected tutorial:

```
Read file: ~/.claude/tutorials/<name>/SKILL.md
```

Then follow the instructions in that SKILL.md to implement the pattern.

The source Xcode project is available at:
```
~/.claude/tutorials/<name>/project/
```

Read source files from that project as needed.

## Available Tags

animation, audio, auth, blur, bottom-sheet, button, calendar, camera, canvas,
card, charts, coredata, drawer, drawing, dynamic-island, firebase, gesture,
glassmorphism, grid, header, iap, json, list, live-activity, loading, location,
login, map, matched-geometry, menu, modal, navigation, networking, notifications,
otp, overlay, pagination, parallax, paywall, pdf, permissions, photos, picker,
popover, realm, scroll, search, shader, share, sheet, shimmer, skeleton, slider,
storekit, swiftdata, swiftui, tabbar, textfield, toast, toolbar, transition, ui,
uikit, video, widget, 3d, alert

## iOS Versions Available

14+, 15+, 16+, 17+, 18+, 26+

## Examples

- `/ios-tutorials carousel` — find carousel tutorials
- `/ios-tutorials animation tab bar` — find animated tab bars
- `/ios-tutorials glassmorphism ios 18` — glassmorphism for iOS 18+
- `/ios-tutorials scroll parallax` — parallax scrolling
- `/ios-tutorials login` — login screens and auth UI
- `/ios-tutorials category:headers` — browse all tutorials in the headers category via tutorials-index.md
- `/ios-tutorials carousel ios:18` — carousels compatible with iOS 18
- `/ios-tutorials tabbar platform:ipad` — tab bars optimized for iPad
