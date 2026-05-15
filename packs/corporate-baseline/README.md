# Pack: `corporate-baseline`

Generic-corporate code-review discipline. Stack-agnostic — applies to any
web codebase regardless of framework / templating / styling choice.

This is the **layer 0** pack: opinionated rules that most corporate
engineering orgs already enforce informally (in PR reviews, in style
guides, in tribal knowledge) but rarely have written down in a single
place that an AI assistant can load on demand.

## When to install

Almost always. The rules here are the floor — what every shipped
codebase should clear before reviewing for stack-specific concerns.

A stack pack (`shopify-theme`, future: `nextjs-app`, `react-spa`,
`django`, etc.) presumes `corporate-baseline` is installed alongside.
Stack packs don't re-state these rules; they add layered discipline on
top.

## Fragments shipped

| File | When it loads | What it enforces |
|---|---|---|
| `code-quality.md` (alwaysApply) | every prompt | Function size ≤40 lines, nesting ≤3, params ≤3, naming conventions, no console.log in shipped code, TODO requires ticket reference |
| `security.md` (alwaysApply) | every prompt | No secrets in source, no PII in inline scripts, sanitize before rendering, CSP discipline |
| `es6-standards.md` (alwaysApply) | every prompt | Modern JS patterns (destructuring, optional chaining, nullish coalescing, template literals, array methods); `const` default; strict equality; `async`/`await` over `.then().catch()` |
| `accessibility-baseline.md` (alwaysApply) | every prompt | WCAG AA floor: alt text, ARIA, focus management, keyboard, contrast, motion |
| `js-deprecations.md` | `var`, `keyCode`, `XMLHttpRequest`, `substr`, `parseInt`, `escape`, `document.write` | Flag deprecated JS APIs, replace on touch |
| `html-anti-patterns.md` | `xlink:href`, `javascript:void`, `<a `, `anchor`, `href=` | Native semantics over rebuilt-with-ARIA; `<button>` for actions, `<a>` for navigation |
| `performance-baseline.md` | `scroll`, `resize`, `setInterval`, `addEventListener`, `image`, `lazy`, `LCP`, `CLS`, `INP` | Async/defer scripts, throttle/debounce, listener cleanup, lazy images, font discipline |
| `error-handling-async.md` | `try`, `catch`, `async`, `await`, `fetch`, `axios`, `service` | Try/catch on API calls, button-disable during requests, sequential awaits, timeouts, retry policy |
| `regression-risk.md` | `delete`, `remove`, `refactor`, `rename`, `modify`, `migration` | Consumer-check on deletion / modification, P1/P2/P3 risk tiers, blast-radius zones |

## What's NOT here (lives in stack packs)

- Framework-specific syntax / lifecycle (`useEffect` cleanup, `onBeforeUnmount`)
- Templating engine rules (Liquid, Handlebars, JSX-specific patterns)
- Stack-specific deprecations (Vue 2 → 3 migration, React class → hooks)
- Specific API conventions (Shopify Cart API, Stripe SDK, Firebase Auth)
- Build / bundler specifics (Webpack vs Vite vs Turbopack)
- Stack-specific architecture patterns (Vue mount, Next.js routing, Remix loaders)

Those belong in stack-specific packs that compose with this baseline.

## Installing

```sh
# At init time:
richardbot-init init --pack corporate-baseline

# With a stack pack on top:
richardbot-init init --pack corporate-baseline --pack shopify-theme

# Add to an existing install:
richardbot-init pack add corporate-baseline
```

## Authoring conventions used here

- **Frontmatter `alwaysApply: true`** only for the 4 highest-leverage
  fragments (code-quality, security, es6-standards, accessibility) — the
  rules every prompt benefits from. Everything else loads on trigger
  match.
- **Stack-neutral examples.** Code samples use vanilla JS, vanilla HTML,
  vanilla CSS, vanilla fetch — no framework imports. Stack packs add
  framework-specific examples on top.
- **Verify sections** at the bottom of each fragment — concrete steps to
  confirm compliance before merge. Reviewers and AI tools should be
  able to mechanically check.

## Customizing

Fork the pack. The fragments are plain markdown — edit to match your
team's specifics (different P1 list, different perf budget, additional
linter rules). The mechanism (frontmatter triggers) is preserved
regardless of content edits.
