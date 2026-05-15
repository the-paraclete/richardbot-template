---
description: Performance discipline — async/defer scripts, throttle/debounce, cleanup intervals, lazy images.
alwaysApply: false
triggers:
  prompt:
    - "scroll"
    - "resize"
    - "setInterval"
    - "setTimeout"
    - "addEventListener"
    - "image"
    - "lazy"
    - "perf"
    - "LCP"
    - "CLS"
---

# Performance

## Scripts

- **No synchronous script loading.** Use `async` (load whenever ready) or `defer` (load in order, after parse). Sync scripts block HTML parse.
- Critical scripts: inline OR `defer`. Non-critical: `async`.

## Listeners

- **Throttle or debounce** scroll, resize, mousemove, input listeners. Most use cases want 16-100ms throttle. Use `lodash.throttle` / `lodash.debounce` or a project-local helper.
- **Always clean up.** `setInterval`, `setTimeout`, `addEventListener` registered in `mounted()` / `onMounted()` MUST be cleared in `beforeUnmount()` / `onBeforeUnmount()`. Otherwise: memory leaks + zombie callbacks firing on unmounted state.

## Images

- **`loading="lazy"`** on every `<img>` that\'s below-the-fold.
- **Explicit `width` and `height`** attributes on every `<img>`. Browser uses these to reserve layout space → no CLS.
- **Use `| image_url: width: X`** for responsive sizes; specify the width you actually need, not the original.

## Liquid loops

- **No nested `{% for %}`** — O(n²) over Shopify collections is fatal. Restructure or paginate.
- **Assign metafield reads to variables.** Don\'t re-fetch inside a loop body.

## Verify

- Lighthouse CI passes (perf score doesn\'t drop on the affected pages).
- Manual: open Network tab, confirm async/defer attributes on script tags.
- Memory: open DevTools Performance recorder during navigation; verify no detached DOM nodes accumulate.
