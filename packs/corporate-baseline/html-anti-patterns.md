---
description: HTML / SVG anti-patterns — xlink:href, javascript:void links, anchors without href. Stack-agnostic web.
alwaysApply: false
triggers:
  prompt:
    - "xlink:href"
    - "javascript:void"
    - "<a "
    - "<a>"
    - "anchor"
    - "href="
---

# HTML / SVG anti-patterns

## Don't

- **`xlink:href`** in SVG: deprecated in SVG 2. Use plain `href`. Browsers still honor `xlink:href` for back-compat, but new code should use `href`.
- **`<a href="javascript:void(0)">`**: not a link — should be a `<button>`. Anchors-as-buttons break navigation expectations, screen-reader announcements (announced as "link" but acts as button), and middle-click open-in-tab.
- **`<a>` without `href`**: same problem — not announced as a link by assistive tech. If it's an action, use `<button>`. If it's a placeholder, finalize the destination before merging.
- **`<button>` inside `<a>`** or **`<a>` inside `<a>`**: interactive nesting; either breaks accessibility or has unpredictable click behavior depending on browser.

## Do

| Want | Use |
|---|---|
| Triggers a JS action | `<button type="button" onClick={...}>` (always specify `type` — defaults to `submit` inside forms) |
| Navigates somewhere | `<a href="real-url">` |
| Toggles state (e.g., menu open) | `<button aria-expanded="true\|false" aria-controls="...">` |
| Submits a form | `<button type="submit">` |
| Cancels / resets | `<button type="reset">` or `<button type="button" onClick={cancel}>` |

## Why this matters

Native semantics carry behavior for free:
- Keyboard focus + Enter/Space activation
- Screen-reader announcement of role
- Middle-click / Cmd-click for open-in-tab (on `<a>`)
- Form submission integration (on `<button>` inside forms)

Rebuilding any of this with `role="button"` + `tabindex="0"` + manual keyboard handlers is error-prone and almost never matches the native behavior exactly.

## Verify

Grep the diff for `<a` and visually confirm each has a meaningful `href` OR is replaced with `<button>`. Same for any SVG with `xlink:`.

```sh
git diff main...HEAD | grep -E '^\+' | grep -E '<a[^>]*\b(href="javascript:|>[^<]*<button|>)' 
```

## Native HTML > ARIA-rewritten div

If you find yourself writing `<div role="button" tabindex="0" onkeydown={handleKeydown}>`, ask whether `<button>` solves the problem with zero added code. Usually yes. The exceptions (a custom interactive widget that has no HTML equivalent) are real but rare.
