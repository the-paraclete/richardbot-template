---
description: Accessibility floor — alt text, ARIA, focus management, keyboard, contrast. WCAG AA minimum. Stack-agnostic.
alwaysApply: true
---

# Accessibility baseline (WCAG AA)

This is the floor. Stack-specific packs may layer additional discipline on top (e.g., Vue's focus-management primitives, React's a11y linter), but every web project ships at least this.

## Required for every interactive element

- **All `<img>` need meaningful alt text.** Decorative images: `alt=""` AND `aria-hidden="true"`.
- **Buttons need visible text OR `aria-label`.** Icon-only buttons must have `aria-label`.
- **Custom clickable elements** (`<div onclick>`, etc.) need `role="button"`, `tabindex="0"`, AND keyboard handlers (Enter + Space). Better: use `<button>` instead.
- **Inputs need `<label>` or `aria-label`.** Placeholder text is NOT a label — it disappears on focus and isn't announced by screen readers.
- **Errors need `aria-live="polite"` or `role="alert"`** so screen readers announce them when they appear.
- **Modals must trap focus** — Tab cycles within, Escape closes, focus restored to trigger on close.
- **No `outline: none`** on focusable elements without a replacement focus indicator (`:focus-visible` styling).

## Contrast & color

- **Sufficient contrast**: WCAG AA = 4.5:1 for normal text, 3:1 for large text and UI components. Use a contrast checker.
- **No color as sole conveyer of meaning.** Pair red/green/etc. with text labels or icons. (~8% of men have some form of color-vision deficiency.)

## Keyboard

- **Every interactive element must be reachable via Tab.** No mouse-only or pointer-only interactions.
- **Tab order must match visual / reading order.** Avoid `tabindex` values > 0 — they create maintenance-fragile tab orders.
- **Custom chords (e.g., Ctrl+K)** should have a single-key alternative if they're a primary action, and must not conflict with screen-reader hotkeys.

## Animation & motion

- **Honor `prefers-reduced-motion: reduce`** — disable non-essential animations when the OS setting is on. CSS:
  ```css
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after { animation: none !important; transition: none !important; }
  }
  ```
- **No content that flashes more than 3 times per second** (seizure trigger).

## Forms

- **Required fields visually indicated** AND announced (`aria-required="true"`).
- **Error states announced** — `aria-invalid="true"` + a linked error message via `aria-describedby`.
- **Don't auto-submit on every keystroke** unless the UI is explicitly a live-search pattern with proper announcements.

## Structure

- **Headings in logical order** — don't skip levels (`<h1>` → `<h3>` without `<h2>`). Screen readers use heading hierarchy as a navigation outline.
- **Single `<main>` per page.** Landmark regions (`<nav>`, `<header>`, `<footer>`, `<aside>`) help screen-reader users skim.
- **Skip-to-content link** at the top of every page that lets keyboard users bypass nav.

## Until automation is wired

Run an axe/pa11y/Lighthouse scan locally before PR. Manual verification of the changed surface:

1. Tab through every interactive element on the changed surface; verify focus visible + logical order.
2. Test with at least one screen reader (VoiceOver on Mac, NVDA on Windows, Orca on Linux) on the happy path.
3. Re-test with `prefers-reduced-motion: reduce` toggled.
4. Re-test at 200% zoom — content should reflow without horizontal scroll.

## When automation IS wired

CI gate on axe-core / jest-axe / pa11y / Lighthouse a11y score. New violations fail the build. Existing violations get a baseline file with a date and a follow-up ticket; don't let the baseline grow.
