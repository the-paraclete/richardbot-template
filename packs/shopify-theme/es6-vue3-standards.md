---
description: ES6+ / Vue 3 patterns required — destructuring, optional chaining, declared props, no unsanitized v-html.
alwaysApply: true
---

# ES6+ & Vue 3 standards

## JavaScript modern

- **Destructure** function params and assignments where it helps: `const { name, id } = user`.
- **Template literals** over concatenation: `\`Hello, ${name}\`` not `"Hello, " + name`.
- **Optional chaining** for nested access: `user?.profile?.avatar` not deeply-nested `&&` guards.
- **Nullish coalescing** for defaults: `value ?? "default"` not `value || "default"` (because `||` treats `0`/`""` as falsy).
- **Spread operator** for clones / merges: `{ ...base, ...overrides }`.
- **Array methods** over manual loops: `.map()`, `.filter()`, `.find()`, `.some()`, `.every()`, `.reduce()`.

## Vue 3 specifics

- **Props must have `type`** AND `default` (or be marked `required: true`).
- **Emits must be declared** via `defineEmits([...])` or `emits: [...]`.
- **Use `computed`** for derived state; never bake derived values into `data()` / `ref()` directly.
- **Composition API preferred** for new components; mixed-API in the same file is a maintenance debt (note in fragility section if you see it).

## XSS prevention

- **No `v-html` without sanitization.** If the source is user input or CMS content, sanitize via DOMPurify (or the team\'s sanitizer of record) before binding.
- **Prefer `v-text` or `{{ }}` interpolation** wherever the content doesn\'t need rendered HTML.

## Verify

- ESLint should catch most of these — run `npm run lint` before PR.
- Manual: grep changed files for `v-html` and confirm the source is sanitized or trusted-static.
