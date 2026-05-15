# `.claude/rules/`

Trigger-loaded context fragments. The fragment-loader hook scans each
`*.md` file's YAML frontmatter on every prompt and injects matching
fragments as additional context for that turn.

## File shape

```markdown
---
description: One-sentence summary of what this rule covers.
alwaysApply: false              # true → load on every prompt (use sparingly)
triggers:
  prompt:
    - "deploy"                  # word-boundary match in the prompt
    - "ship it"
globs:
  - "src/checkout/**"           # path-prefix mention in the prompt
  - "*.deploy.yml"
---

# <Title of the rule>

Body. Plain markdown. Keep under ~500 lines; split larger topics into
multiple fragments. The body is injected into context when ANY trigger
fires.
```

## Trigger semantics

| Field            | Fires when                                                            |
|------------------|-----------------------------------------------------------------------|
| `alwaysApply`    | Every prompt. Use for the 2–4 truly cross-cutting rules.              |
| `triggers.prompt`| Any token appears as a whole word in the prompt (case-insensitive).   |
| `globs`          | A path-shaped token in the prompt has a prefix matching any glob.     |
| (none)           | Manual only — invoked via Read / tool call by the agent.              |

A rule fires if **any** of its triggers match. Up to 5 fragments load
per turn (configurable via `RICHARDBOT_MAX_RULES_PER_TURN`).

## Authoring guidelines

- **One topic per file.** If a fragment splits naturally into two themes,
  it should be two files.
- **Under ~500 lines.** Long rule files defeat the lazy-load benefit.
- **Concrete over abstract.** Example commands beat principle statements.
- **Don't restate the spine.** `CLAUDE.md` carries the non-negotiables;
  rules carry the specifics.
- **Frontmatter is the contract.** Triggers are how the hook finds you;
  pick tokens the agent will actually emit.

## Surface-vertical vs tech-vertical chunking

For codebases that span multiple tech layers (e.g., a Shopify theme with
Liquid + Vue + SCSS + JS), prefer **per-functional-surface** fragments
(`surface-checkout.md`, `surface-cart.md`, `surface-product.md`) over
**per-tech-layer** (`vue.md`, `liquid.md`, `scss.md`).

A task usually touches one functional surface across all its tech layers
— so loading the vertical slice for that surface beats loading every
tech layer separately.

Tech-layer fragments are still useful for genuinely cross-cutting concerns
(state-management patterns, build conventions, perf budgets).
