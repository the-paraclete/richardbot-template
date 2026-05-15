---
description: Async safety + error handling — try/catch on API calls, button-disable during requests, sequential awaits.
alwaysApply: false
triggers:
  prompt:
    - "try"
    - "catch"
    - "async"
    - "await"
    - "fetch"
    - "service"
    - "cart"
    - "promise"
---

# Async safety & error handling

## All API calls need try/catch

Every call into `cart.service.js`, `bundle.service.js`, `reviews.service.js`, raw `fetch()`, etc. must be wrapped in try/catch.

```js
try {
  const result = await cartService.addItem({ id, quantity });
  // happy path
} catch (err) {
  // surface to user via error state — never silent swallow
  this.errorMessage = "Couldn\'t add to cart. Please try again.";
  console.error("addItem failed:", err);  // OK in catch with reason
}
```

**No empty `catch {}` blocks.** If you intentionally suppress, comment why.

## Disable buttons during API calls

For any user-triggered action that fires a request:

1. Set `loading` / `submitting` state at request start
2. Render the button with `:disabled="loading"`
3. Clear state in `finally` (so it clears on both success and error paths)

Prevents double-submit. Especially critical for Add to Cart (double-click → two line items).

## Sequential cart operations

Cart API calls can race. If your flow needs A then B then C against the cart:

```js
// Right: serial
await cartService.add(itemA);
await cartService.add(itemB);
await cartService.update(itemC);

// Wrong: parallel — Shopify cart races, last-write-wins, state corrupted
await Promise.all([cartService.add(a), cartService.add(b)]);
```

## User-facing error state

Every error case needs a visible-or-announced state — banner, inline message, toast. Never silently log and move on.

## Verify

- Trigger the error path manually (network throttle / mock failure) — confirm UI shows error, button re-enables, no zombie loading state.
- For cart flows: test with browser network throttling at 3G; confirm no double-submits possible during the request window.
