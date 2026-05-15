---
description: Regression / incident-risk checklist — when deleting or modifying code, check consumers and blast radius.
alwaysApply: false
triggers:
  prompt:
    - "delete"
    - "remove"
    - "refactor"
    - "rename"
    - "modify"
    - "change"
    - "deprecate"
    - "breaking change"
---

# Regression risk — deletion & modification checklist

## For every deletion

Before removing a function / component / snippet / CSS class:

1. **Grep the repo for usage** — function name, component tag, snippet filename, CSS class. Include `.liquid`, `.vue`, `.js`, `.scss`, `.html`.
2. **Check theme settings JSON** — `config/settings_data.json`, `templates/*.json` for section/block references.
3. **Check inline event handlers** — `onClick="someFn()"` in Liquid attributes.
4. **Confirm no test fixture depends on it.**

If ANY consumer found: either migrate the consumer in the same PR, or don\'t delete.

## For every modification

When changing a function signature, component prop, emit name, store action, CSS class name, or Liquid snippet parameter list:

1. **Find every caller / consumer.**
2. **Verify each still works** — pass updated args, handle renamed events, update CSS references.
3. **Flag in PR body** if you renamed a public API — reviewers should confirm callers updated.

## Production-incident risk levels

| Tier | Surfaces | What breaks if you regress |
|---|---|---|
| 🔴 **P1 — critical flows** | Add to Cart, Checkout, Cart Drawer, Subscription toggle, Engraving, Payment | Revenue stops. Customers can\'t complete purchases. |
| 🟠 **P2 — degraded experience** | Pricing display, line-item quantity, tracking, accessibility | Customers complete checkout but experience is worse / metrics break. |
| 🟡 **P3 — cosmetic / non-blocking** | Hero banners, content sections, blog | Visible but doesn\'t stop conversions. |

## High blast radius

Watch for changes to:

- **Shared utilities** (`src/vue/utilities/`, `src/vue/helpers/`) — touched by many components
- **Pinia stores** — state shared across the app
- **Liquid snippets included in many places** (e.g., `card-product.liquid`)
- **Theme settings** — affects every render

Changes here need extra-careful consumer audit + manual smoke through P1 flows.

## Verify

Test plan in PR body must include: every consumer touched, manual smoke through P1 flows, regression-test status on the suite. No "should work" — verified-or-not.
