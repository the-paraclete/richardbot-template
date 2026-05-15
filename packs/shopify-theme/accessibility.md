---
description: Accessibility floor — alt text, ARIA, focus management, keyboard, contrast. WCAG AA minimum.
alwaysApply: true
---

# Accessibility

## Required

- **All `<img>` need meaningful alt text.** Decorative images: `alt=""` AND `aria-hidden="true"`.
- **Buttons need visible text OR `aria-label`.** Icon-only buttons must have `aria-label`.
- **Custom clickable elements** (`<div onclick>`) need `role="button"`, `tabindex="0"`, and keyboard handlers (Enter + Space).
- **Inputs need `<label>` or `aria-label`.** Placeholder is not a label.
- **Errors need `aria-live="polite"` or `role="alert"`** so screen readers announce them.
- **Modals must trap focus** — Tab cycles within, Escape closes, focus restored to trigger on close.
- **No `outline: none`** without a replacement focus indicator (`:focus-visible` styling).
- **Sufficient contrast**: WCAG AA — 4.5:1 normal text, 3:1 large text / UI elements.
- **No color as sole conveyer of meaning** — pair with text or icon.

## Animation

- Honor `prefers-reduced-motion: reduce` — disable non-essential animations when set.

## Verify

- Tab through every interactive element on the changed surface; verify focus visible + logical order.
- Test with VoiceOver / NVDA on at least one happy path through the changed surface.
- Run an axe/pa11y scan locally before PR.

## When automation is wired

Until axe-core / jest-axe / pa11y is in the test suite, manual verification is required for every UI change. Document compliance in the PR test plan.
