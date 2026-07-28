#!/usr/bin/env python3
"""
Build catalog.json from all tutorial SKILL.md files in ~/.claude/tutorials/.
Run after adding or removing tutorials.

Usage:
    python3 ~/.claude/skills/ios-tutorials/build-catalog.py
"""

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

TUTORIALS_DIR = Path.home() / ".claude" / "tutorials"
OUTPUT_FILE = Path.home() / ".claude" / "tutorials" / "catalog.json"


def parse_frontmatter(content: str) -> dict:
    """Extract YAML frontmatter from SKILL.md content."""
    match = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return {}

    frontmatter = {}
    current_key = None
    current_value = ""

    for line in match.group(1).split("\n"):
        # Handle multiline values (description with >)
        if current_key and line.startswith("  "):
            current_value += " " + line.strip()
            frontmatter[current_key] = current_value.strip()
            continue
        elif current_key and current_value:
            current_key = None
            current_value = ""

        # Handle key: value pairs
        kv = re.match(r"^(\w+):\s*(.*)", line)
        if kv:
            key = kv.group(1)
            value = kv.group(2).strip()

            # Handle multiline indicator
            if value == ">":
                current_key = key
                current_value = ""
                continue

            value = value.strip('"').strip("'")

            # Parse tags array
            if key == "tags":
                tags_match = re.findall(r'"([^"]+)"', kv.group(2))
                frontmatter[key] = tags_match
            else:
                frontmatter[key] = value

    return frontmatter


def build_catalog():
    if not TUTORIALS_DIR.exists():
        print(f"Error: {TUTORIALS_DIR} does not exist", file=sys.stderr)
        sys.exit(1)

    tutorials = []
    errors = []

    for entry in sorted(TUTORIALS_DIR.iterdir()):
        if not entry.is_dir():
            continue

        skill_md = entry / "SKILL.md"
        if not skill_md.exists():
            errors.append(f"Missing SKILL.md: {entry.name}")
            continue

        try:
            content = skill_md.read_text(encoding="utf-8")
        except Exception as e:
            errors.append(f"Read error {entry.name}: {e}")
            continue

        fm = parse_frontmatter(content)

        tutorials.append({
            "name": fm.get("name", entry.name),
            "description": fm.get("description", ""),
            "platform": fm.get("platform", "ios"),
            "min_ios": fm.get("min_ios", ""),
            "tags": fm.get("tags", []),
            "source_project_path": fm.get("source_project_path", ""),
            "path": entry.name,
        })

    catalog = {
        "version": 1,
        "generated": datetime.now(timezone.utc).isoformat(),
        "count": len(tutorials),
        "tutorials": tutorials,
    }

    OUTPUT_FILE.write_text(
        json.dumps(catalog, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    print(f"Catalog built: {len(tutorials)} tutorials -> {OUTPUT_FILE}")
    if errors:
        print(f"Warnings ({len(errors)}):")
        for err in errors:
            print(f"  - {err}")


if __name__ == "__main__":
    build_catalog()
