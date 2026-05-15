# richardbot-template

A drop-in template that gives any repo a **fractal / lazy-loaded context system**
for Claude Code. Instead of a single monolithic `CLAUDE.md` that loads on every
prompt, the template ships small frontmatter-tagged fragments that load only
when their triggers fire.

## What's in the box

```
<your repo>/
├── CLAUDE.md                            # thin spine (~50 lines). Always loaded.
├── .claude/
│   ├── settings.json                    # wires the fragment-loader hook
│   ├── hooks/
│   │   └── prompt-fragment-loader.sh    # UserPromptSubmit hook (bash + jq)
│   ├── rules/                           # trigger-loaded context fragments
│   │   ├── README.md                    # authoring shape
│   │   ├── conventions.md               # always-loaded — repo conventions
│   │   ├── secrets.md                   # always-loaded — secret handling
│   │   ├── client-repo.md               # always-loaded — what this repo IS
│   │   ├── pr-flow.md                   # always-loaded — how PRs land here
│   │   └── <your-surfaces>.md           # add one per functional surface
│   └── commands/                        # role files for subprocess dispatch
│       ├── architect.md                 # opus
│       ├── dev.md                       # sonnet
│       ├── qa.md                        # sonnet
│       ├── scan.md                      # haiku
│       └── postmortem.md                # opus
└── .richardbot-memory/                   # acute project memory (writable)
    ├── README.md
    └── _recent.md
```

Plus optional **packs** layered onto the baseline. Two layers:

```
packs/
├── corporate-baseline/                  # Layer 0 — generic-corporate (almost always installed)
│   ├── code-quality.md                  #   function size, naming, comments
│   ├── security.md                      #   XSS, secrets, PII, sanitization
│   ├── es6-standards.md                 #   modern JS patterns
│   ├── accessibility-baseline.md        #   WCAG AA floor
│   ├── js-deprecations.md               #   var, keyCode, etc.
│   ├── html-anti-patterns.md            #   native semantics, no a-as-button
│   ├── performance-baseline.md          #   async/defer, throttle, cleanup, lazy
│   ├── error-handling-async.md          #   try/catch, button-disable, timeouts
│   └── regression-risk.md               #   deletion / modification checklist
└── shopify-theme/                       # Layer 1 — stack-specific (Shopify OS 2.0)
    ├── architecture.md                  #   Vue mount, Liquid → Vue data flow
    ├── vue3-standards.md                #   props/emits/computed/Composition API
    ├── vue3-deprecations.md             #   Vue 2 → Vue 3 patterns
    ├── liquid-conventions.md            #   image_url, render, bounded loops
    ├── tailwind-itcss.md                #   utility-first, ITCSS layer order
    └── shopify-cart-api.md              #   line item keys, properties validation
```

## Why a separate `.richardbot-memory/` outside `.claude/`?

Claude Code's built-in sensitive-file gate matches `.claude/<subdir>/` and
blocks the Write tool on those paths — even for a repo's own local `.claude/`.
Acute memory is written by the agent during work (postmortems, friction notes),
so it must live where the agent can write freely. The split also clarifies
intent: `.claude/rules/` is human-authored, versioned config;
`.richardbot-memory/` is agent-written state, append-only.

## Install / Survey / Update

```sh
# From inside your repo:
bash /path/to/richardbot-template/bin/richardbot-init init      # scaffold
bash /path/to/richardbot-template/bin/richardbot-init survey    # detect stack + propose surface chunks
bash /path/to/richardbot-template/bin/richardbot-init update    # refresh framework files only

# Add packs (layered discipline). The recommended combo for a Shopify theme:
bash /path/to/richardbot-template/bin/richardbot-init pack add corporate-baseline
bash /path/to/richardbot-template/bin/richardbot-init pack add shopify-theme
```

`init` refuses to overwrite existing `CLAUDE.md` or `.claude/` — use `update`
to refresh just the framework files (hook, settings, READMEs).

`corporate-baseline` is generic-corporate code-review discipline that applies
to any web codebase. Stack packs (`shopify-theme`, future: `nextjs-app`,
`react-spa`, etc.) presume `corporate-baseline` is installed alongside.

## How the trigger system works

| Frontmatter         | Fires when                                                             |
|---------------------|------------------------------------------------------------------------|
| `alwaysApply: true` | Every prompt. For 2-4 truly cross-cutting rules only.                  |
| `triggers.prompt:`  | Any listed token appears as a whole word in the prompt (case-insens.). |
| `globs:`            | A path-shaped token in the prompt has a prefix matching any glob.     |
| (none of the above) | Manual — agent invokes via Read or tool call.                          |

A fragment fires if ANY trigger matches. Up to 5 fragments load per turn
(configurable via `RICHARDBOT_MAX_RULES_PER_TURN`).

## Authoring a rule

```markdown
---
description: One-sentence summary.
alwaysApply: false
triggers:
  prompt: ["deploy", "ship it"]
globs: ["src/checkout/**"]
---

# Body of the rule

Plain markdown. Keep under ~500 lines; split if larger.
```

## Authoring a role file

Role files in `.claude/commands/` declare the model + effort for subprocess
dispatch:

```markdown
---
description: One-line role summary.
model: sonnet         # haiku | sonnet | opus
effort: medium        # low | medium | high
---

You are a <role>. ...
```

Invoke a role as a subprocess (separate from the parent's model):

```sh
claude --print --model sonnet \
       --output-format json \
       "$(cat .claude/commands/dev.md)\n\nTask: <what to do>"
```

## Surface-vertical chunking

For multi-layer codebases (e.g., a Shopify theme spanning Liquid + Vue + SCSS),
prefer **per-functional-surface** fragments (`surface-checkout.md`,
`surface-cart.md`) over per-tech-layer (`vue.md`, `liquid.md`). A task usually
touches one surface across all its tech layers, so loading the vertical slice
beats loading every tech layer. Cross-cutting concerns (state, build, perf)
stay tech-layer-shaped.

## Dependencies

`bash` 4+, `jq`, `grep`, `awk`, `cat`, `find`. No python. No sqlite. No npm.
Claude Code itself.

## Status

Skeleton — primitives work end-to-end; refinement comes through using it on
real repos.
