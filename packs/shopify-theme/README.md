# Pack: `shopify-theme`

Shopify-specific overlay on `corporate-baseline`. Layered discipline for
Shopify Online Store 2.0 themes built on Liquid + Vue 3 + Pinia +
Tailwind + SCSS (ITCSS) + Webpack + EJS.

**Presumes `corporate-baseline` is installed alongside.** The generic
rules (code quality, security, accessibility floor, ES6+ standards, JS
deprecations, HTML anti-patterns, perf baseline, error handling,
regression risk) live there — this pack doesn't restate them. It adds
the Shopify-stack-specific layer on top.

## Install

```sh
# Recommended: both packs together
richardbot-init init --pack corporate-baseline --pack shopify-theme

# Add to an existing install
richardbot-init pack add corporate-baseline
richardbot-init pack add shopify-theme
```

## Fragments shipped

| File | When it loads | What it enforces |
|---|---|---|
| `architecture.md` | `data-vue-root`, `json--`, `service.js`, `tracking`, `datalayer`, `componentName` | Vue mount pattern (`data-vue-root="ComponentName"`); Liquid → Vue data flow via `json--*.liquid` snippets or `data-*` attrs; services layer (`src/vue/services/*.service.js`); tracking modules |
| `vue3-standards.md` (alwaysApply) | every prompt | Vue 3 specifics: props need `type` + `default`, declared `emits`, `computed` for derived state, Composition API preference, reactivity gotchas (destructuring, `.value`, `v-model`) |
| `vue3-deprecations.md` | `this.$on`, `Vue.set`, `v-for`, `v-if`, `filter`, `$listeners` | Vue 2 → Vue 3 migration patterns |
| `liquid-conventions.md` | `img_url`, `image_url`, `include`, `{% render`, `{% for`, `.liquid` | Liquid filters (`image_url` not `img_url`), `render` not `include`, bounded `{% for %}` with `limit:`, no nested loops |
| `tailwind-itcss.md` | `tailwind`, `scss`, `inline style`, `!important`, `BEM`, `ITCSS` | Tailwind utilities first, ITCSS layer order, mobile-first responsive, BEM for SCSS components |
| `shopify-cart-api.md` | `cart.add`, `cart.change`, `/cart/`, `line item`, `properties`, `variant_id` | Use line item `key` (not `id`/`variant_id`) when variants collide; validate `properties` before sending; `_`-prefixed props are hidden; common gotchas |

## What this pack does NOT cover

These live in `corporate-baseline`:

- Function size / nesting / naming conventions → `code-quality.md`
- WCAG AA floor → `accessibility-baseline.md`
- XSS, secrets, PII in inline scripts → `security.md`
- Modern ES6+ patterns → `es6-standards.md`
- Deprecated browser JS APIs (var, keyCode, XMLHttpRequest) → `js-deprecations.md`
- HTML anti-patterns (`xlink:href`, `javascript:void`, `<a>` without href) → `html-anti-patterns.md`
- Generic perf (async/defer, throttle/debounce, listener cleanup, lazy images) → `performance-baseline.md`
- Try/catch on API calls, button-disable during requests, sequential awaits → `error-handling-async.md`
- Deletion / modification consumer-check, P1/P2 tiers → `regression-risk.md`

If a fragment in this pack feels duplicative of a baseline fragment,
it's because the baseline rule applies AND the Shopify stack adds a
specific overlay (e.g., generic perf says "lazy images"; shopify says
"and use `| image_url: width: X`").

## Stack-specific gotchas captured here

The discipline encoded in this pack came from real Shopify-theme PR
review criteria. Each fragment maps to a class of regression that
shipped at least once to production:

- **`architecture.md`**: components not registered in
  `src/vue/components/index.js` silently fail to mount — typo-friendly
  failure mode.
- **`vue3-deprecations.md`**: Vue 2 patterns surviving in code copied
  from older themes; reactivity quietly breaks.
- **`liquid-conventions.md`**: nested `{% for %}` over
  `collections.all` taking down PLPs at high traffic.
- **`shopify-cart-api.md`**: `change.js` with `variant_id` hitting the
  wrong line when engraving fees create duplicate variants.

## Targets

Authored against / tested on:
- `cotyorg/philosophy-com.myshopify.com`
- Other Coty Shopify Plus theme repos following the same conventions
- Should drop in cleanly to any Online Store 2.0 theme on the same stack

Stack-specific values (specific component names, deploy-target list,
specific surface inventories) live in the target repo's own
`.claude/rules/surface-*.md` fragments, not in this pack.

## Composing with other stack packs

A repo may install multiple stack packs if it spans stacks (rare for a
single theme). Most common composition:

```
corporate-baseline   # always
  └── shopify-theme  # if this is a Shopify Online Store 2.0 theme
```

Future composition (when those packs exist):

```
corporate-baseline
  ├── shopify-theme       # Shopify storefront work
  └── nextjs-app          # Next.js admin tool living in the same monorepo
```
