# richardbot-template

A drop-in template that gives any repo a **fractal / lazy-loaded context system**
for Claude Code. Instead of a single monolithic `CLAUDE.md` that loads on every
prompt, the template ships small frontmatter-tagged fragments that load only
when their triggers fire — plus a full **dev cycle** of role files for
subprocess dispatch, a **lease primitive** for cross-process coordination,
and **MCP server packs** for opt-in tool integrations.

## What's in the box

```
<your repo>/
├── CLAUDE.md                            # thin spine (~50 lines). Always loaded.
├── .mcp.json                            # MCP server config (post mcp install)
├── .claude/
│   ├── settings.json                    # wires the fragment-loader hook
│   ├── env                              # env-var slots for MCP servers + tools
│   ├── hooks/
│   │   ├── prompt-fragment-loader.sh    # UserPromptSubmit hook
│   │   ├── block-destructive.sh         # PreToolUse Bash gate
│   │   ├── protect-paths.sh             # PreToolUse Edit/Write gate
│   │   ├── session-orient.sh            # SessionStart context
│   │   └── lease-{acquire,release,heartbeat,check}.sh   # cross-process work-in-flight markers
│   ├── state/
│   │   └── leases/                      # active lease files (gitignored .json)
│   ├── rules/                           # trigger-loaded context fragments
│   │   ├── README.md                    # authoring shape
│   │   ├── conventions.md               # always-loaded
│   │   ├── dev-cycle.md                 # always-loaded — the 10-stage cycle
│   │   ├── gate-discipline.md           # /review|/qa|/scan gate contracts
│   │   ├── pr-flow.md                   # PR body shape + merge gates
│   │   ├── secrets.md                   # always-loaded — never-commit list
│   │   ├── client-repo.md               # external-repo discipline
│   │   └── <your-surfaces>.md           # add one per functional surface
│   └── commands/                        # role files for subprocess dispatch
│       ├── triage.md                    # haiku  — routes work
│       ├── architect.md                 # opus   — designs; no code
│       ├── designer.md                  # opus   — interaction shape (UI work)
│       ├── dev.md                       # opus   — writes tests OR code
│       ├── review.md                    # opus   — code-quality gate
│       ├── qa-tests.md                  # sonnet — meaningful-tests check
│       ├── qa.md                        # sonnet — end-to-end (+Puppeteer for FE)
│       ├── pm.md                        # sonnet — sequences dispatches
│       ├── ship.md                      # sonnet — commit/push/PR/CI
│       ├── docs.md                      # sonnet — sweep stale docs
│       ├── scan.md                      # haiku  — audit a surface
│       └── postmortem.md                # opus   — why-it-broke writeups
├── .richardbot-memory/                  # acute project memory (writable)
│   ├── README.md
│   └── _recent.md
└── tests/                               # bash test suites for hooks
    ├── lease/                           # tests for the lease primitive
    └── mcp/                             # tests for mcp install/remove
```

## The dev cycle

`dev-cycle.md` (always-loaded) declares a 10-stage canonical flow for any
artifact-producing work:

```
Triage → Architect → Designer → Dev → Review → QA-tests → QA → UAT → Ship → Docs
```

Each stage has a role file in `.claude/commands/` that declares its model
in frontmatter. The dispatcher cats the role file plus the task into a
`claude --print --model <X>` subprocess. **Three blocking gates** run
after Dev: code-quality review (opus), tests-are-meaningful check (sonnet),
and end-to-end QA (sonnet, with Puppeteer for FE work). UAT is a human
stage between QA and Ship — gated on the operator's nod.

The cycle is generic — every project gets it. Per-project rules layer on
top via `.claude/rules/*.md` fragments.

## The lease primitive

`.claude/hooks/lease-{acquire,release,heartbeat,check}.sh` provide a minimal
file-based cross-process work-in-flight marker. A dispatched subprocess
acquires a lease before starting; other windows / agents can check the
lease state to know what's running. JSON state files at
`.claude/state/leases/<slug>.json` carry slug, intent, pid, host,
started_at, heartbeat_at. Stale leases (>30 min since last heartbeat)
get flagged for reaping.

```sh
.claude/hooks/lease-acquire.sh   my-work "fixing the cart 422 bug"
.claude/hooks/lease-heartbeat.sh my-work       # call from your long-running loop
.claude/hooks/lease-check.sh                   # list all active leases
.claude/hooks/lease-release.sh   my-work       # on completion
```

## MCP packs

Six optional MCP server integrations ship in `packs/mcp-*`:

- `mcp-shopify` — Shopify dev-tooling (schema, doc search, Liquid validation). No token.
- `mcp-circleci` — CircleCI pipeline access (`CIRCLECI_TOKEN`).
- `mcp-sentry` — Sentry error tracking (`SENTRY_AUTH_TOKEN`, `SENTRY_ORG`).
- `mcp-jira` — Jira ticket access (`JIRA_URL`, `JIRA_USER`, `JIRA_API_TOKEN`).
- `mcp-slack` — Slack messaging (`SLACK_BOT_TOKEN`).
- `mcp-aws` — AWS resource queries (SSO via `AWS_PROFILE`).

Each pack's README documents what it gives the agent, how to provision
auth, security gravity, and when not to install. The `.mcp.json.template`
at the repo root carries all six stanzas; `richardbot-init mcp install`
prompts per-server and writes a filtered `.mcp.json` to the target repo.

```sh
richardbot-init mcp list                                # show what's installed + available
richardbot-init mcp install circleci sentry             # interactive install
richardbot-init mcp install circleci --keys-from .env   # non-interactive (CI setup)
richardbot-init mcp remove circleci                     # strip the stanza (env vars preserved)
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
bash /path/to/richardbot-template/bin/richardbot-init mcp install <name>   # opt into MCP integrations
```

`init` refuses to overwrite existing `CLAUDE.md` or `.claude/` — use `update`
to refresh just the framework files (hooks, settings, role files, READMEs).

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
model: opus           # haiku | sonnet | opus
effort: high          # low | medium | high
---

You are a <role>. ...
```

Invoke a role as a subprocess (separate from the parent's model):

```sh
claude --print \
       --model "$(awk '/^model:/{print $2}' .claude/commands/dev.md)" \
       --output-format json \
       "$(cat .claude/commands/dev.md)

TASK: <what to do>"
```

## Surface-vertical chunking

For multi-layer codebases (e.g., a Shopify theme spanning Liquid + Vue + SCSS),
prefer **per-functional-surface** fragments (`surface-checkout.md`,
`surface-cart.md`) over per-tech-layer (`vue.md`, `liquid.md`). A task usually
touches one surface across all its tech layers, so loading the vertical slice
beats loading every tech layer. Cross-cutting concerns (state, build, perf)
stay tech-layer-shaped.

## Dependencies

`bash` 4+, `jq`, `grep`, `awk`, `cat`, `find`, `mktemp`. No npm dependency for
the framework itself. The MCP server packages have their own runtime needs
(usually `npx` to fetch the server on demand). Claude Code itself for the
agent surface.

## Status

Skeleton — primitives work end-to-end (lease tests pass, mcp install/remove
tests pass). Refinement comes through using it on real repos.
