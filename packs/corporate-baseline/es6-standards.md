---
description: Modern JS patterns required — destructuring, optional chaining, template literals, array methods. Stack-agnostic.
alwaysApply: true
---

# ES6+ JavaScript standards

Applies anywhere modern JS runs — browser, Node, Deno, edge runtimes.

## Use the modern primitives

- **Destructuring** for function params and assignments where it clarifies intent:
  ```js
  const { name, id } = user;
  function render({ title, body }) { ... }
  ```
- **Template literals** over string concatenation:
  ```js
  `Hello, ${name}`             // good
  "Hello, " + name             // worse
  ```
- **Optional chaining** for nested access:
  ```js
  user?.profile?.avatar        // good
  user && user.profile && user.profile.avatar  // worse
  ```
- **Nullish coalescing** for defaults:
  ```js
  value ?? "default"           // treats null/undefined as missing
  value || "default"           // wrong: also replaces "", 0, false
  ```
- **Spread operator** for clones / merges:
  ```js
  { ...base, ...overrides }    // shallow merge
  [...arr, item]               // append without mutation
  ```
- **Array methods** over hand-written loops:
  ```js
  items.map(x => x.id)
  items.filter(x => x.active)
  items.find(x => x.id === target)
  items.some(x => x.error)
  items.reduce((acc, x) => acc + x.qty, 0)
  ```

## Use `const` by default, `let` when needed, never `var`

`var` is function-scoped and hoists in surprising ways. `let` is block-scoped. `const` makes intent clearer and catches reassignment bugs at parse time.

## Use strict equality

```js
value === null              // good
value == null               // wrong intent — matches null OR undefined
```

If you want "null or undefined", say so explicitly:
```js
value === null || value === undefined
// or:
value == null    // OK if you're INTENTIONALLY matching both AND the codebase convention agrees
```

## Async patterns

- **Prefer `async`/`await` over `.then().catch()` chains.** Easier to read, easier to step through, integrates with stack traces.
- **Always `await` a promise you care about.** Unawaited promises become unhandled rejections; common source of test flakes and prod logging noise.
- **Sequential `await` is intentional.** If A and B are independent, use `Promise.all([a, b])` for concurrency. If they're dependent, serial `await` is correct.

## Modules over globals

- Use `import` / `export`. No `window.X = ...` for cross-module communication.
- Side-effect-only imports are fine when registering plugins / extending prototypes, but flag them in PR review so reviewers know what's being loaded for side effects.

## Verify

- ESLint catches most of these — run `npm run lint` before PR.
- Grep the diff for `var ` (leading space) — any new `var` is a violation.
- Grep for `==` / `!=` (without trailing `=`) — flag for review.
- For promises: grep for `.then(` and verify each is intentional (vs `await` would be clearer).
