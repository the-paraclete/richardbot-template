---
description: Deprecated JS APIs — flag on touch, replace with modern equivalent. Stack-agnostic browser JS.
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

If you see any of these in code you're modifying, replace them. If you see them in code you're NOT modifying, flag in the PR body as a follow-up — don't widen scope mid-PR, but make sure the rot is visible.

| Deprecated | Use instead | Why |
|---|---|---|
| `var x = ...` | `const x = ...` (or `let` if reassignment needed) | `var` hoists, function-scopes; `const`/`let` are block-scoped + catch reassignment bugs |
| `e.keyCode` | `e.key` (`"Enter"`, `"Escape"`, etc.) | `keyCode` is unreliable across keyboards/locales; deprecated by spec |
| `document.write(...)` | DOM manipulation (`appendChild`, `insertAdjacentHTML`) | `document.write` blocks parser, breaks if called post-load |
| `new XMLHttpRequest()` | `fetch()` with `await` | Modern; promise-based; cleaner error handling |
| `str.substr(start, length)` | `str.substring(start, end)` or `str.slice(start, end)` | `substr` is non-standard / deprecated |
| `escape(s)` / `unescape(s)` | `encodeURIComponent(s)` / `decodeURIComponent(s)` | `escape`/`unescape` don't handle Unicode correctly |
| `parseInt(s)` (no radix) | `parseInt(s, 10)` | Legacy: `"08"` could parse as octal; always specify radix |
| `.then().catch()` chains | `try { await ... } catch (e) { ... }` | Easier to read, integrates with stack traces |
| `== null` / `!= null` | `=== null` / `=== undefined`, or `=== null \|\| === undefined` explicitly | Loose equality is a source of bugs; explicit intent is safer |

## Verify

Grep the diff for each pattern. If any appear in NEW code (not just pre-existing), they must be fixed before merge:

```sh
git diff main...HEAD -- '*.js' '*.ts' '*.vue' '*.jsx' '*.tsx' | grep -E '^\+' | grep -E '\b(var |\.substr\(|XMLHttpRequest|document\.write|keyCode)\b'
```

If the diff is clean, you're good. If not, fix or comment explicitly waiving with reviewer.
