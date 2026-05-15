---
description: Performance baseline — async/defer scripts, throttle/debounce, cleanup listeners, lazy images. Stack-agnostic web.
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
    - "FID"
    - "INP"
---

# Performance baseline

Applies to any web frontend. Stack-specific packs may add framework-specific rules (Liquid loops for Shopify, RSC boundaries for Next.js, etc.).

## Script loading

- **No synchronous script loading.** Use `async` (load whenever ready) or `defer` (load in order, after parse). Sync scripts block HTML parse and tank Time-to-Interactive.
- **Critical inline scripts**: inline OR `defer`. Non-critical: `async`.
- **Don't import the world.** Tree-shake; check bundle visualizer (`webpack-bundle-analyzer`, `vite-bundle-visualizer`) when adding deps.

## Listeners

- **Throttle or debounce** scroll, resize, mousemove, wheel, and input listeners. Most cases want 16-100ms throttle. Use `lodash.throttle` / `lodash.debounce`, a project-local helper, or `requestAnimationFrame` for visual updates.
- **Always clean up.** `setInterval`, `setTimeout`, `addEventListener` registered in any component-mount lifecycle MUST be cleared in the corresponding unmount lifecycle:
  ```js
  // React
  useEffect(() => {
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, []);

  // Vue 3
  onMounted(() => window.addEventListener('scroll', handler));
  onBeforeUnmount(() => window.removeEventListener('scroll', handler));
  ```
  Otherwise: memory leaks + zombie callbacks firing on unmounted state.

## Images

- **`loading="lazy"`** on every below-the-fold `<img>`. Above-the-fold images: `fetchpriority="high"` if it's the LCP candidate.
- **Explicit `width` and `height` attributes** on every `<img>`. Browser uses these to reserve layout space → no CLS.
- **Modern formats**: WebP / AVIF where possible. Most CDN image services emit these automatically when the `Accept` header allows.
- **Responsive `srcset` + `sizes`** for images that vary by viewport. Don't ship a desktop hero to mobile.

## Fonts

- **`font-display: swap`** so text renders with fallback font while the web font loads.
- **Preload critical fonts**: `<link rel="preload" as="font" href="..." crossorigin>` for the font used in the LCP element.
- **Subset fonts** to the character set actually used (Latin, plus any glyphs for the locale).

## Network

- **Avoid waterfalls.** Dependent requests in series add up; parallelize what you can.
- **Cache aggressively.** Static assets with content hashes get year-long `Cache-Control`; APIs use ETag/Last-Modified where the data allows.
- **Don't poll if you can SSE / WebSocket.** Don't WebSocket if you can long-poll. Don't long-poll if HTTP/2 multiplexing is enough.

## Loops and rendering

- **No nested loops over large collections** (O(n²)). Restructure or paginate.
- **Memoize expensive derived values.** React: `useMemo` / `useCallback`. Vue: `computed`. Pure JS: cache by input.
- **Virtualize long lists** (>100 items). `react-virtual`, `vue-virtual-scroller`, or roll your own.

## Verify

- **Lighthouse CI** passes — perf score doesn't drop on the affected pages.
- **Real-user metrics** (RUM) — LCP < 2.5s, INP < 200ms, CLS < 0.1 at p75.
- **Manual**: open Network tab, confirm async/defer attributes on script tags; throttle to 3G and verify the page still loads in a reasonable time.
- **Memory leak check**: open DevTools Performance recorder during navigation through the changed surface; verify no detached DOM nodes accumulate.

## Budgets

If the project has a perf budget in CI, the PR must not exceed it. Common budgets:
- Total JS bundle < 200KB compressed
- LCP < 2.5s at p75 on 4G
- TTI < 5s at p75 on 4G

If you exceed a budget, the right move is to land the feature behind a flag while you optimize — not to silently widen the budget.
