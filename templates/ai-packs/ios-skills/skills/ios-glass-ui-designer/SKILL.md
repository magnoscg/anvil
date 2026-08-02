---
name: ios-glass-ui-designer
description: Design and review purposeful Liquid Glass interfaces in SwiftUI with availability, accessibility, hierarchy, and rendering cost treated as first-class constraints.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# iOS Glass UI Designer

Use this skill when Liquid Glass is explicitly requested for an Apple-platform interface. Preserve the product hierarchy first; glass is a system material, not a decorative layer to place behind every view.

## Intake

Before proposing code, determine:

- the deployment target and Xcode toolchain;
- which screens and controls need glass;
- the existing design tokens and navigation structure;
- accessibility requirements, including Reduce Transparency and Reduce Motion;
- a fallback for operating systems that do not provide the requested APIs.

Check the installed SDK or current Apple documentation before naming an API. Gate new behavior with availability checks and keep the fallback visually complete.

## Design sequence

1. Mark content, navigation, controls, and transient overlays on the screen.
2. Reserve glass for controls or surfaces whose context benefits from showing through.
3. Use system components first because they inherit platform behavior and accessibility.
4. Apply custom effects after layout and appearance modifiers.
5. Group nearby custom glass elements in the appropriate effect container so they render and transition as one intentional system.
6. Add tint only to express state or prominence; never use it as the sole status signal.
7. Use interactive material only on actual controls.

## Review rules

- Text contrast must remain legible over the lightest and darkest reachable content.
- Hit targets, focus order, labels, Dynamic Type, and VoiceOver grouping remain valid at every size.
- Morphing identities must be stable and unique within their namespace.
- Motion must communicate continuity and remain understandable when reduced.
- Dense lists and scrolling surfaces should not create one effect container per cell.
- Screenshots are insufficient for approval: inspect scroll, resize, appearance, content changes, and transitions on device or simulator.

## Performance check

Profile the real screen when several effects are visible. Reduce the number of independent effects before lowering visual quality elsewhere. Watch for animation hitches, offscreen rendering pressure, and repeated view invalidation.

## Deliverable

Return a hierarchy sketch, availability strategy, component-level rules, accessibility checklist, and a short validation plan. Include code only after the project target and SDK have been verified.
