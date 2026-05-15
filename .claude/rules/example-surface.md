---
description: Example — per-functional-surface rule fragment. Replace with your real surface.
alwaysApply: false
triggers:
  prompt:
    - "checkout"
    - "cart-drawer"
    - "payment"
globs:
  - "src/checkout/**"
  - "src/components/cart/**"
---

# Surface — checkout

(Replace this example with your actual checkout surface conventions.)

## What lives here

- Page entry: `src/checkout.js`
- Vue tree: `src/components/cart/`, `src/components/checkout/`
- Liquid templates: `templates/cart.liquid`, `sections/checkout-*.liquid`
- Styles: `src/scss/sections/_checkout.scss`

## Conventions specific to this surface

- All cart mutations go through the `cart` Vuex store. Never mutate
  `state.cart` directly from a component.
- Address validation lives in `src/components/checkout/AddressForm.vue`.
  Add new validators to its `validators` registry; don't bypass.
- Currency symbols are rendered via the `formatPrice` filter, not
  string-concatenated. The filter handles locale + minor-unit rounding.

## Known fragilities

- The `discount-app` integration assumes the Shopify cart payload has a
  `discount_codes` array. If empty, Shopify omits the field — handle
  the undefined case in `cart/applyDiscount`.
- iOS Safari intermittently double-fires the `pageshow` event on
  bfcache restore. Guard `mounted()` hooks that initialize state.

## How to verify changes here

- Run the cart unit suite: `npm run test -- src/components/cart`
- Smoke-test in dev shop with 3+ items, mixed currency, applied discount.
- Lighthouse: cart page LCP must stay under 2.5s (gates CI).
