---
description: Async safety + error handling — try/catch on API calls, button-disable during requests, sequential awaits. Stack-agnostic.
alwaysApply: false
triggers:
  prompt:
    - "try"
    - "catch"
    - "async"
    - "await"
    - "fetch"
    - "promise"
    - "axios"
    - "request"
    - "service"
---

# Async safety & error handling

## All API calls need try/catch

Every call into a service / SDK / `fetch()` / `axios` / `pg.query` must be wrapped in try/catch (or `.catch()` if the codebase prefers promise chains).

```js
try {
  const result = await api.createOrder({ items, address });
  // happy path: update state, redirect, etc.
} catch (err) {
  // surface to user via error state — never silent swallow
  setError("Couldn't place your order. Please try again.");
  // log with context — what was being attempted
  console.error("createOrder failed:", { items, err });
}
```

**No empty `catch {}` blocks.** If you intentionally suppress (rare, narrow cases — e.g., best-effort logging), comment why.

## Disable buttons during API calls

For any user-triggered action that fires a request:

1. Set `loading` / `submitting` state at request start
2. Render the button with `:disabled="loading"` (or framework equivalent)
3. Clear state in `finally` (so it clears on both success and error paths)

```js
async function handleSubmit() {
  loading.value = true;
  try {
    await api.submit(payload);
    redirectToSuccess();
  } catch (err) {
    setError(err.message);
  } finally {
    loading.value = false;
  }
}
```

**Why this matters.** Without disable: a double-click fires two POSTs. For idempotent reads, harmless. For non-idempotent mutations (add to cart, submit payment, send email), you get duplicates → support tickets, refund requests, angry customers.

## Sequential vs parallel awaits

API calls can race. If your flow needs A then B then C against shared state:

```js
// Right: serial
await api.add(itemA);
await api.add(itemB);
await api.update(itemC);

// Wrong: parallel against shared mutable state
await Promise.all([api.add(itemA), api.add(itemB)]);
// Server-side last-write-wins; state may be corrupted.
```

If A and B are genuinely independent (different resources, no shared mutable state), `Promise.all` is correct AND faster. Pick deliberately based on what's being mutated.

## User-facing error state

Every error case needs a visible-or-announced state — banner, inline message, toast. Never silently log and move on.

For accessibility: error UI should use `role="alert"` or `aria-live="polite"` so screen readers announce it.

## Network failures vs application errors

Distinguish:
- **Network failure** (offline, DNS, timeout): user message is "Connection problem — please try again." Retry is reasonable; offer a retry button.
- **HTTP 4xx**: user message is specific ("That email is already registered", "Invalid card number"). Don't auto-retry — the request itself was wrong.
- **HTTP 5xx**: user message is generic ("Something went wrong on our end. Please try again."). Auto-retry with backoff IS reasonable for idempotent reads; manual retry for writes.

## Timeouts

Long-running requests need timeouts. A fetch that never resolves is worse than one that fails:

```js
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 30_000);
try {
  const response = await fetch(url, { signal: controller.signal });
  // ...
} catch (err) {
  if (err.name === 'AbortError') {
    setError("Request timed out. Please try again.");
  } else {
    setError("Couldn't complete request.");
  }
} finally {
  clearTimeout(timeout);
}
```

## Retry policy

If you retry: exponential backoff with jitter. Don't hammer the failing endpoint:

```js
async function withRetry(fn, { tries = 3, base = 200 } = {}) {
  for (let i = 0; i < tries; i++) {
    try { return await fn(); }
    catch (err) {
      if (i === tries - 1) throw err;
      const delay = base * 2 ** i + Math.random() * base;
      await new Promise(r => setTimeout(r, delay));
    }
  }
}
```

Don't retry non-idempotent operations (POST that creates a resource) without an idempotency key.

## Verify

- Trigger the error path manually (network throttle, mock failure, kill the API) — confirm UI shows error, button re-enables, no zombie loading state.
- For mutation flows: test with browser network throttling at 3G; confirm no double-submits possible during the request window.
- Tests should include the error path, not just the happy path. Mock the API rejecting and assert the UI shows the error.
