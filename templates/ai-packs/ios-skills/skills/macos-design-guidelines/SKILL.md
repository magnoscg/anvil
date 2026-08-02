---
name: macos-design-guidelines
description: Design and review native macOS interfaces around windows, menus, commands, keyboard access, data density, accessibility, and platform conventions.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# macOS Design Guidelines

Use this skill for a macOS or Mac Catalyst interface. Verify current framework APIs in the installed SDK before proposing code; this document defines product decisions rather than fixed signatures.

## Platform model

A Mac app is a collection of persistent, resizable windows operated by keyboard, pointer, menus, and automation as well as direct controls. Start by defining documents, windows, selection, and commands. Do not scale an iPhone screen into a desktop window.

## Workflow

1. Identify whether the app is document-based, library-based, utility, menu-bar, or mixed.
2. Define window types, restoration behavior, minimum useful sizes, and multi-window rules.
3. Build a command map before the screen map: name each action, its availability, menu placement, shortcut, toolbar representation, and undo behavior.
4. Choose navigation that fits data depth: sidebar, split view, inspector, tabs, or separate windows.
5. Design selection and focus states for keyboard and pointer use.
6. Test resizing, full screen, multiple displays, appearance changes, and state restoration.

## Interaction rules

- Put discoverable actions in the menu bar even when they also appear in a toolbar or context menu.
- Reuse established shortcuts and avoid claiming system-reserved combinations.
- Make destructive actions explicit, reversible when possible, and compatible with undo.
- Preserve selection when opening inspectors or secondary windows.
- Use context menus as accelerators, never as the only route to an action.
- Support drag and drop only when source, destination, copy/move semantics, and cancellation are clear.

## Layout and content

Allow information density without sacrificing hierarchy. Tables need meaningful columns, sorting rules, empty states, and horizontal-resize behavior. Toolbars should contain frequent actions, not every command. Inspectors edit the current selection and must explain mixed values. Respect safe areas, title-bar behavior, and user-controlled window size.

## Accessibility and input

Validate full keyboard navigation, VoiceOver order, labels, focus visibility, increased contrast, reduced motion, and large text where supported. Pointer hover is supplementary; it cannot be the only status cue. All custom controls need roles, names, values, and actions.

## Review checklist

Check first launch, no document, one item, many items, multiple selection, offline/error state, window restoration, menu validation, undo/redo, shortcut conflicts, drag cancellation, and multi-display movement. Record both platform deviations and the product reason for each one.
