---
name: swift-charts
description: Design, implement, and review Swift Charts visualizations by starting from the analytical question, then validating marks, scales, interaction, accessibility, and performance.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Swift Charts

Use this skill when an Apple-platform product needs a chart or an existing chart is misleading, inaccessible, slow, or difficult to interact with.

## Start with the question

Write the sentence the chart must help a person answer. Then choose the encoding:

- comparison across categories: bars or points;
- change over an ordered dimension: lines or areas;
- composition of a meaningful whole: sectors only when labels remain clear;
- distribution: points, rectangles, or binned bars;
- relationship between variables: points, with a third dimension only when it adds interpretable value.

Do not choose a mark because it looks impressive. Avoid dual axes unless the relationship and scales are unambiguous.

## Implementation workflow

1. Inspect the deployment target and current Charts API in the installed SDK.
2. Define a small `Identifiable` data model with stable identity and explicit units.
3. Normalize missing, zero, and outlier behavior before constructing marks.
4. Set domains deliberately when automatic domains would distort comparisons.
5. Encode the primary distinction by position; use color and symbol as supporting channels.
6. Add selection, scrolling, or annotations only when they answer a product need.
7. Provide a textual summary and useful accessibility labels for marks.
8. Test empty, single-value, dense, negative, localized, and large Dynamic Type states.

## Availability

Gate newer plot types and 3D charts by the deployment target. Keep a two-dimensional or tabular fallback that preserves the analytical answer. Verify exact signatures against the active SDK rather than relying on remembered examples.

## Accessibility

The chart cannot be the only representation of critical information. Supply a concise trend summary, units, meaningful mark descriptions, and a navigable alternative for dense datasets. Never rely on color alone; verify contrast in both appearances and with common color-vision filters.

## Performance

Keep transformation work outside the chart builder, use stable identity, and prefer vectorized plot APIs when supported and justified by the dataset. Profile the real interaction before adding sampling; if sampling is necessary, document what information it removes.

## Review output

Return the analytical question, data assumptions, chosen encodings, availability boundary, accessibility alternative, edge cases, and the tests that demonstrate the visualization remains truthful.
