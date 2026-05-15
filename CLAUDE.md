# <PROJECT NAME>

<One paragraph: what this repo is. Tech stack one-liner.>

## Location

- Repo: `<git remote slug>`
- Work clone: `<path on dev machine>`
- CI: `<provider + what it gates on>`

## Non-negotiables

1. <Project-specific load-bearing rule #1>
2. <Project-specific load-bearing rule #2>
3. <…3-5 more, each one sentence>

## How context loads here

Most rules don't live in this file. They live in `.claude/rules/*.md` as small,
trigger-loaded fragments. The fragment-loader hook reads each rule's
frontmatter on every prompt and injects matching ones into the turn — so
your boot context stays small and the rules that DO load are the ones the
current task actually needs.

| Trigger type      | Frontmatter field          | When it fires                                |
|-------------------|----------------------------|----------------------------------------------|
| Always            | `alwaysApply: true`        | Every prompt                                 |
| Prompt keyword    | `triggers.prompt: [tok…]`  | Prompt contains any token (word-boundary)    |
| Path / glob       | `globs: [pattern…]`        | Prompt mentions a path matching the glob     |
| Manual            | (no triggers)              | User invokes via tool / slash command        |

See `.claude/rules/README.md` for the authoring shape.

## Skills (subprocess dispatch, model-explicit)

The dev cycle uses `claude --print --model <X>` subprocesses for work that
produces a written artifact. Each role file in `.claude/commands/*.md`
declares its model. Suggested defaults:

| Role         | Model   | What it does                                              |
|--------------|---------|-----------------------------------------------------------|
| architect    | opus    | Designs systems; no code; outputs design docs             |
| dev          | sonnet  | Writes tests OR code, never both same pass; tests-first   |
| qa           | sonnet  | Verifies what was built; PASS/FAIL/NEEDS-REVISION         |
| scan         | haiku   | Audits a code surface; finds drift, dead code, smells     |
| postmortem   | opus    | Why-it-broke writeups; updates rules                      |

Invoke: `claude --print --model sonnet "$(cat .claude/commands/dev.md)" + "<task>"`
