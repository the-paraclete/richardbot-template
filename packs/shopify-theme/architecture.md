---
description: Vue mount registration, Liquid→Vue data flow, services layer, tracking modules.
alwaysApply: false
triggers:
  prompt:
    - "data-vue-root"
    - "json--"
    - "service.js"
    - "tracking"
    - "datalayer"
    - "componentName"
---

# Architecture conventions

## Vue mount pattern

- Components mount via `data-vue-root="ComponentName"` attribute in Liquid:
  ```html
  <div data-vue-root="ProductInfo" data-props='{{ product_props_json }}'>
    <!-- Vue mounts here -->
  </div>
  ```
- **Every new component must be registered** in `src/vue/components/index.js`. Without registration, `main.js` won\'t mount it; Vue will silently fail to render.
- The component name in `data-vue-root` MUST exactly match the registration key. Typos = silent no-mount.

## Liquid → Vue data flow

Two channels:

1. **`json--*.liquid` snippets** — for structured data. Render JSON into a `<script type="application/json">` block, fetch from Vue setup.
2. **`data-*` attributes** — for small primitives (ids, flags). Read via `props` in Vue.

**Don\'t** put data in inline script tags (`<script>window.foo = {{ data }}</script>`) — XSS vector, breaks CSP.

## Services layer

- **All API calls go through `src/vue/services/*.service.js`.** Components must NOT call `fetch()` or `/cart/add.js` directly.
- New API surface → new method in the relevant service. Components import the service and call its methods.
- Tests target the service (mock fetch); components remain UI-only.

## Tracking

- **Tracking goes through `src/vue/tracking/*.js` modules** — `onAddToCart`, `onMiniCartView`, `onProductImpression`, etc.
- Components call tracking via injected `$tracking` or `inject(\'tracking\')`.
- Don\'t call `window.dataLayer.push()` / `window.adobeDataLayer.push()` directly from a component. The tracking modules abstract the dual-write to GTM + Adobe Launch.

## Verify

- Grep the changed files: new components have registration in `index.js`; new API calls go through a service; new tracking events go through a tracking module.
- If you see `fetch(` or `window.dataLayer.push(` in a component, that\'s a violation worth raising in review.
