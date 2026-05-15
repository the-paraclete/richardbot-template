---
description: Styling discipline — Tailwind utilities over custom CSS, ITCSS layer order, mobile-first responsive.
alwaysApply: false
triggers:
  prompt:
    - "tailwind"
    - "scss"
    - ".css"
    - "inline style"
    - "!important"
    - "BEM"
    - "ITCSS"
---

# Styling conventions

## Tailwind first

- **Prefer Tailwind utilities** over custom CSS for layout, spacing, color, typography.
- **No inline `style="..."` attributes** unless the value is genuinely dynamic (computed from data). Inline styles bypass the design system.
- **No `!important`** without an explicit comment justifying why (third-party override, etc.).

## Responsive

- **Mobile-first**: base styles first, then progressively wider breakpoints: `class="text-sm md:text-base lg:text-lg"`.
- Use the breakpoint scale defined in `bedrock.config.js` (xs:475, sm:768, md:990, lg:1024, xl:1280).
- Don\'t hardcode pixel breakpoints in custom SCSS — reference the Tailwind / Bedrock config.

## SCSS (when Tailwind isn\'t enough)

ITCSS layer order, low → high specificity:

1. **settings/** — variables, design tokens
2. **tools/** — mixins, functions
3. **base/** — reset, typography, fonts (element selectors only)
4. **objects/** — layout patterns (`.o-container`, `.o-grid`)
5. **components/** — UI components (`.c-card`, `.c-button`)
6. **sections/** — section-specific styles (page composition)
7. **trumps/** — utility overrides (`.u-text-center`)

Higher layers can override lower; never the reverse. Don\'t put component styles in `base/`.

## Selector hygiene

- **No ID selectors.** Use classes; IDs make specificity wars.
- **Nesting ≤ 3 levels deep.** Beyond that, factor a new class.
- **No hardcoded colors outside `settings/`.** All color values reference design tokens.
- **BEM** for component CSS: `.c-card__title--featured`.

## Verify

- Stylelint catches most of this — run `npm run lint:css` before PR.
- Visual: spot-check that new styles land in the right ITCSS layer.
