---
description: Shopify Cart API specifics — line item keys, properties validation, common gotchas.
alwaysApply: false
triggers:
  prompt:
    - "cart.add"
    - "cart.change"
    - "cart.update"
    - "/cart/"
    - "line item"
    - "line_item"
    - "properties"
    - "variant_id"
---

# Shopify Cart API

## Line items: use `key`, not `id` or `variant_id`

When multiple cart items share the same `variant_id` (e.g., the same product added twice with different engraving fees), Shopify distinguishes them by the line item **key**.

| Operation | Use |
|---|---|
| Identify a specific line | `item.key` |
| Update quantity of a specific line | POST `/cart/change.js` with `id: item.key` |
| Remove a specific line | same — `id: item.key` |

Using `variant_id` for change/remove operations on a cart with duplicate variants will silently affect the WRONG line (typically the first one matching).

## Properties

- **Validate the `properties` object before sending.** Shopify silently drops malformed properties — your line item will land in the cart MISSING the property you thought you set.
- **Property names starting with `_` are hidden** from the cart display (used for line-item metadata like `_engraving`, `_added_by`, `_bundle_id`).
- **Values must be strings.** Objects, arrays, numbers get coerced / dropped unpredictably; stringify yourself.

## Common gotchas

- **`/cart.js` is unauthenticated, same-origin** — anyone running JS on the storefront can mutate the cart. Treat `properties` as untrusted on the server side; verify any gating (eligibility, pricing) server-side too.
- **`/cart/clear.js`** removes ALL items including any free-sample / GWP additions. After clearing, the cart-watching logic may need a moment to re-add eligible promo items.
- **`/cart/update.js` vs `/cart/change.js`** — `update` accepts a full updates object; `change` modifies a single line by key. Pick deliberately.

## Verify

- For any cart mutation touched: manually test with a cart that has DUPLICATE variants. Confirm change/remove hits the right line.
- For property-setting code: add the item, inspect `/cart.js` response, confirm the property landed.
- For clear flows: verify GWP / free samples re-add correctly after a `clear`.
