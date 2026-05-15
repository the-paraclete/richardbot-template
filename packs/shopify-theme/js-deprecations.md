---
description: Deprecated JS APIs — flag on touch, replace with modern equivalent.
alwaysApply: false
triggers:
  prompt:
    - "var"
    - "keyCode"
    - "XMLHttpRequest"
    - "substr"
    - "parseInt"
    - "document.write"
    - "escape("
    - "unescape("
---

# JS deprecations — replace on touch

If you see any of these in code you\'re modifying, replace them. If you see them in code you\'re NOT modifying, flag in the PR body as a follow-up.

| Deprecated | Use instead |
|---|---|
| `var x = ...` | `const x = ...` (or `let` if reassignment needed) |
| `e.keyCode` | `e.key` (`"Enter"`, `"Escape"`, etc.) — `keyCode` is unreliable across keyboards/locales |
| `document.write(...)` | DOM manipulation (`appendChild`, `insertAdjacentHTML`) — `document.write` blocks parser |
| `new XMLHttpRequest()` | `fetch()` with `await` |
| `str.substr(start, length)` | `str.substring(start, end)` or `str.slice(start, end)` — `substr` is non-standard / deprecated |
| `escape(s)` / `unescape(s)` | `encodeURIComponent(s)` / `decodeURIComponent(s)` |
| `parseInt(s)` (no radix) | `parseInt(s, 10)` — implicit radix can guess 8 for `"08"` in legacy contexts; always specify |
| `.then().catch()` | `try { await ... } catch (e) { ... }` — easier to follow, integrates with async/await flow |
| `== null` (intent: catch null + undefined) | `=== null` (strict) or explicit `=== null || === undefined` |

## Verify

Grep the diff for each pattern. If any appear in NEW code (not just pre-existing), they must be fixed before merge.
