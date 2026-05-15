---
description: Regression / incident-risk checklist — when deleting or modifying code, check consumers and blast radius. Stack-agnostic.
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
    - "migration"
---

# Regression risk — deletion & modification checklist

## For every deletion

Before removing a function / component / class / config key / API endpoint / CSS class / template snippet:

1. **Grep the repo for usage** — function name, component name, class name, key string. Search all file types the codebase uses (`.js`, `.ts`, `.vue`, `.jsx`, `.tsx`, `.html`, `.liquid`, `.scss`, `.css`, `.yml`, `.json`, `.md`).
2. **Check config / data files** — JSON config (`config/*.json`, `tsconfig.json`), env defaults, schema files, fixture files.
3. **Check inline event handlers** in templates (`onClick="someFn()"`).
4. **Check dynamic references** — string-keyed lookups like `components[name]`, `actions[type]` — these don't show up in plain grep but break at runtime.
5. **Confirm no test fixture depends on it.**
6. **Check external consumers** — if this is a library / public API, check the README, downstream repos, and any docs that may reference it.

If ANY consumer found: either migrate the consumer in the same PR, or don't delete.

## For every modification

When changing a function signature, component prop, emit name, store action, CSS class name, API response shape, or any other publicly-consumed contract:

1. **Find every caller / consumer.**
2. **Verify each still works** — pass updated args, handle renamed events, update CSS references.
3. **Flag in PR body** if you renamed a public API — reviewers should confirm callers updated.
4. **If the rename is mechanical**, run it as a separate commit (rename only, no behavior change) so reviewers can diff small.

## Production-incident risk levels

Adapt the tier list to your domain. For an e-commerce frontend:

| Tier | Surfaces | What breaks if you regress |
|---|---|---|
| 🔴 **P1 — critical flows** | Add to Cart, Checkout, Payment, Account creation, Auth | Revenue stops. Customers can't complete purchases. |
| 🟠 **P2 — degraded experience** | Pricing display, line-item quantity, tracking, accessibility, search | Customers complete checkout but experience is worse / metrics break. |
| 🟡 **P3 — cosmetic / non-blocking** | Hero banners, content sections, blog, footer | Visible but doesn't stop conversions. |

For a B2B SaaS / API product, the tiers will be different — define them in `client-repo.md` or a project-local fragment. The discipline is the same: rank by blast radius.

## High blast radius — extra-careful zones

Changes to these need extra-careful consumer audit + manual smoke through P1 flows:

- **Shared utilities** (`utils/`, `helpers/`, `lib/`) — touched by many sites in the codebase
- **State stores** (Pinia, Redux, Zustand, etc.) — state shared across the app
- **Shared components** (used in many places — generic `<Button>`, `<Modal>`, `<Input>`)
- **Theme / design tokens** — affect every render
- **API client / service layer** — every feature flows through it
- **Auth / session middleware** — security-critical AND blast-radius-wide

## What to put in the PR

Test plan in PR body must include:

- **Every consumer touched** — list them so reviewers can verify
- **Manual smoke through P1 flows** — checkbox per flow
- **Regression-test status** — suite passed, coverage on changed files ≥ project target
- **No "should work"** — verified-or-not

## Anti-patterns

- **"It's a small change."** Small changes to shared code have huge blast radius. The size of the diff doesn't predict the size of the impact.
- **"Just one consumer."** Until grep shows zero, you don't know that. Grep first.
- **"I'll migrate the consumer in a follow-up."** Then this PR is incomplete and shouldn't merge. Either migrate now or don't delete now.
- **"The tests cover it."** Coverage measures lines hit, not behaviors verified. A green suite + a broken consumer is a real failure mode.

## Verify

- Run the full test suite, not just the touched files.
- Manual smoke through every consumer you found.
- Lighthouse / a11y / perf budgets pass.
- If the change touches an API contract: the API contract spec / docs updated in the same PR.
