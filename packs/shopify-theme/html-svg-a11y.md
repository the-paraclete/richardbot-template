---
description: HTML / SVG anti-patterns — xlink:href, javascript:void links, anchors without href.
alwaysApply: false
triggers:
  prompt:
    - "xlink:href"
    - "javascript:void"
    - "<a "
    - "<a>"
    - "anchor"
---

# HTML / SVG anti-patterns

## Don\'t

- **`xlink:href`** in SVG: deprecated in SVG2. Use plain `href`. Browsers still honor `xlink:href` for compat but new code should use `href`.
- **`<a href="javascript:void(0)">`**: not a link — should be a `<button>`. Anchors without a real URL break navigation expectations, screen-reader announcements, and middle-click open-in-tab.
- **`<a>` without `href`**: same problem — not announced as a link by assistive tech. If it\'s an action, use `<button>`. If it\'s a placeholder, finalize the destination before merging.

## Do

| Want | Use |
|---|---|
| Triggers a JS action | `<button type="button" onClick=...>` |
| Navigates somewhere | `<a href="real-url">` |
| Toggles state (e.g., menu open) | `<button aria-expanded="true|false" aria-controls="...">` |

## Verify

Grep the diff for `<a` and visually confirm each has a meaningful `href` OR is replaced with `<button>`. Same for any SVG with `xlink:`.
