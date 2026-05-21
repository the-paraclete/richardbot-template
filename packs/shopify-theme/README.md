# Pack: `shopify-theme`

Reviewer-grade discipline for Shopify Online Store 2.0 themes built on
Liquid + Vue 3 + Pinia + Tailwind + SCSS (ITCSS) + Webpack + EJS.

Derived from production-team PR review criteria. Each fragment loads
only when its triggers match — Liquid-specific rules don't fire when
you're working on Vue components, and vice versa.

## Fragments shipped (planned)

| File | Triggers | What it enforces |
|---|---|---|
| `code-quality.md` (alwaysApply) | — | Function size ≤40 lines, nesting ≤3, params ≤3, naming conventions, no console.log, TODO requires ticket number |
| `accessibility.md` (alwaysApply) | — | alt text required, button labels, ARIA, focus trap on modals, no `outline:none` without replacement |
| `es6-vue3-standards.md` (alwaysApply) | — | Modern JS patterns (destructuring, optional chaining, nullish coalescing), declared props/emits, NO unsanitized v-html |
| `js-deprecations.md` | `var`, `keyCode`, `XMLHttpRequest`, `substr`, `parseInt`, `escape`, `then().catch`, `document.write` | Flag deprecated JS APIs |
| `vue3-deprecations.md` | `this.$on`, `Vue.set`, `v-for`, `v-if`, `filter`, `$listeners` | Vue 3 deprecated patterns |
| `liquid-conventions.md` | `img_url`, `image_url`, `include`, `render`, `{% for %}` | Liquid filter/include/loop rules |
| `html-svg-a11y.md` | `xlink:href`, `javascript:void`, `<a>` | HTML anti-patterns |
| `tailwind-itcss.md` | `tailwind`, `scss`, `inline style`, `!important` | Utility-first; ITCSS layer order |
| `performance.md` | `scroll`, `resize`, `setInterval`, `addEventListener`, `image`, `lazy` | Throttle/debounce + cleanup discipline |
| `regression-risk.md` | `delete`, `refactor`, `modify`, `change`, `remove` | Check-consumers checklist + P1/P2 risk classification |
| `error-handling.md` | `try`, `catch`, `await`, `fetch`, `cart` | Try/catch on API calls, button-disable, await-sequential |
| `shopify-cart-api.md` | `cart.add`, `cart.change`, `line item`, `properties` | Use line item key for variant collisions; validate properties before sending |
| `architecture.md` | `data-vue-root`, `json--`, `service.js`, `tracking` | Vue mount registration; data-flow conventions |

## Status

**Architecture shipped, content pending.** Pack primitive works; the 13
fragments above are queued for the next authoring session. The content
is straightforward to write — each fragment is a chunking of an
already-written team review criteria document. ETA ~½ day of authoring.

## Targets

Authored against / tested on:
- Shopify Plus theme repos following common Online Store 2.0 conventions

Should drop in cleanly to any Online Store 2.0 theme on the same stack.
Stack-specific values (specific component names, deploy-target list,
etc.) live in the target repo's own `.claude/rules/surface-*.md`
fragments, not in this pack.
