# Packs

Opinionated rule-fragment bundles. The baseline template ships
*universal* rules in `.claude/rules/` (conventions, secrets, pr-flow,
client-repo) — these are the things every repo using this template
gets unconditionally.

**Packs add layered discipline on top of the universal baseline.** Each
pack is a curated set of fragments for a specific concern.

## Available packs

### Layer 0 — generic-corporate (almost always installed)

- **`corporate-baseline`** — Stack-agnostic corporate code-review
  discipline. Function size, security baseline (XSS, secrets, PII),
  WCAG AA accessibility floor, modern ES6+ standards, JS deprecations,
  HTML anti-patterns, performance baseline, async/error handling,
  regression-risk consumer-check.

### Layer 1 — stack-specific (one or more, depending on the codebase)

- **`shopify-theme`** — Shopify Online Store 2.0 themes (Liquid + Vue 3
  + Tailwind + ITCSS + Shopify Cart API). Presumes
  `corporate-baseline` is installed alongside.

(Planned packs: `nextjs-app`, `react-spa`, `node-service`, `python-django` — open issues to vote.)

## How packs compose

```
.claude/rules/                       # the always-shipped baseline rules
├── conventions.md                   # coding/commit/PR conventions
├── secrets.md                       # secret handling
├── client-repo.md                   # what this repo is
└── pr-flow.md                       # how PRs land

packs/corporate-baseline/            # generic-corporate discipline
├── code-quality.md                  # function size, naming, comments
├── security.md                      # XSS, secrets, PII, sanitization
├── es6-standards.md                 # modern JS patterns
├── accessibility-baseline.md        # WCAG AA floor
├── js-deprecations.md               # var, keyCode, etc.
├── html-anti-patterns.md            # native semantics over rebuilt ARIA
├── performance-baseline.md          # async/defer, throttle, cleanup, lazy
├── error-handling-async.md          # try/catch, button-disable, timeouts
└── regression-risk.md               # deletion / modification checklist

packs/shopify-theme/                 # Shopify-specific overlay
├── architecture.md                  # Vue mount, Liquid → Vue data flow, services
├── vue3-standards.md                # Vue 3 props/emits/computed/Composition API
├── vue3-deprecations.md             # Vue 2 → Vue 3 patterns
├── liquid-conventions.md            # image_url, render, bounded for-loops
├── tailwind-itcss.md                # utility-first, ITCSS layer order
└── shopify-cart-api.md              # line item keys, properties validation
```

When a consumer installs a pack, the fragments get copied into the
target repo's `.claude/rules/`. The fragment-loader hook then surfaces
them on matching prompts, same as any other rule. **No new mechanism**
— packs are just opinionated sets of rule files curated for a concern.

## Pack philosophy

- **One concept per fragment.** Don't bundle "code quality + security +
  accessibility" into one 300-line file; split into separate fragments
  with their own triggers so the AI loads only what the prompt needs.
- **Frontmatter is load-bearing.** `alwaysApply: true` for the 2-4
  highest-leverage rules per pack; everything else loads on
  prompt-token trigger. Don't `alwaysApply` more than a handful per
  pack — the loader has a budget.
- **Stack-neutral examples in baseline.** Vanilla JS, vanilla HTML, no
  framework imports. Stack packs add framework-flavored examples.
- **Each fragment ends with a "Verify" section.** Concrete steps to
  confirm compliance — what to grep, what to run, what to manually
  check. Reviewers and AI tools should be able to mechanically check.
- **Edit, don't fork blindly.** Fragments are plain markdown. Most
  packs include lines that are right for 90% of teams; tweak the 10%
  for your specifics rather than maintaining a divergent fork.

## Installing packs

```sh
# At init time — recommended combo for a Shopify-theme repo:
richardbot-init init --pack corporate-baseline --pack shopify-theme

# Add to an existing install:
richardbot-init pack add corporate-baseline
richardbot-init pack add shopify-theme

# List installed packs:
richardbot-init pack list

# Remove a pack (preserves any of its rules you've edited):
richardbot-init pack remove corporate-baseline
```

## Authoring a new pack

1. Create `packs/<your-stack>/`
2. Write a `README.md` explaining: what it covers, what it presumes is
   already installed, what stack packs it composes with
3. Add `.md` rule fragments with appropriate frontmatter triggers
   (see `../.claude/rules/README.md` for the rule shape)
4. Each fragment: one concept; frontmatter triggers; "Verify" section
   at the bottom; stack-flavored examples
5. Test with `richardbot-init pack add <your-stack>` on a sample repo
6. Document expected triggers and which surfaces it applies to

Packs version with the template itself. A breaking pack change should
bump the template version. Submit packs as PRs to this repo or as
external repos that follow the same shape (`packs/<name>/`) — the
loader doesn't care which.

## Layering convention

The convention this template encourages:

- **`.claude/rules/`** = repo-specific facts (what THIS repo is, what
  conventions THIS team holds, what's protected here). Human-authored;
  rarely changes.
- **`packs/corporate-baseline/`** = generic-corporate discipline that
  applies to almost every codebase. Mostly stable.
- **`packs/<stack>/`** = stack-specific layered discipline. May
  evolve faster as the stack evolves.
- **`.richardbot-memory/`** = agent-writable findings (bugs, friction,
  postmortems). Refreshed via `rescan`.

This separation means: when a stack pack updates upstream, you can
`richardbot-init pack update <stack>` and get the fresh rules without
losing your repo-specific customizations in `.claude/rules/`.
