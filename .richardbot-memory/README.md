# `.richardbot-memory/`

Project-acute memory. Lives **outside** `.claude/` deliberately — Claude
Code's built-in sensitive-file gate matches `.claude/<subdir>/` and
blocks the Write tool on those paths. Acute memory is written by the
agent during work (postmortems, friction notes, dated learnings), so it
must live where the agent can write freely.

## What goes here

- **Postmortems**: when something broke, write why + what would have
  prevented it. Filename: `postmortem_<topic>_YYYY-MM-DD.md`.
- **Friction notes**: when a workflow felt awkward, capture the workaround
  + a suggestion. Filename: `friction_<area>_YYYY-MM-DD.md`.
- **Dated learnings**: anything you'd want a future agent (or future you)
  to see when working in this codebase. Filename: `<topic>_YYYY-MM-DD.md`.
- **`_recent.md`**: append-only digest. One line per new memory, newest
  on top. The fast-scan index.

## What does NOT go here

- **Rules** (versioned, human-reviewed) — those go in `.claude/rules/`.
- **Secrets** of any kind — this directory IS checked into git by default.
- **Ephemeral debug output** — that's `/tmp/`.

## Frontmatter

Same shape as a rule file, but `description` is the primary key for
search; triggers are optional.

```markdown
---
description: One-sentence summary. Will appear in prefetch surfacing.
date: 2026-05-14
type: postmortem | friction | learning
triggers:
  prompt: ["<token>", "<token>"]
---

# <Topic>

Body. Concrete. File:line citations beat narrative.
```

## How memory surfaces back

The `prompt-fragment-loader.sh` hook reads `.richardbot-memory/*.md`
exactly the same way it reads `.claude/rules/*.md` — frontmatter
triggers, body injection. A memory note is just a rule fragment with a
different filesystem home.

## Copilot consumers

This directory is dual-target. Claude Code reads it automatically via the
`prompt-fragment-loader.sh` hook (above). GitHub Copilot reads and writes
it **by hand**, following `.github/copilot-instructions.md` §2 — the
discipline file that ships at the top of every Copilot session.

Same files, same `_recent.md` digest format. The digest line format the
Copilot preamble §2b instructs is identical to the one above:

```
YYYY-MM-DD <type> <filename> — <one-line summary>
```

So a note written by a Claude session and a note written by a Copilot
session land in the same place, in the same shape. `copilot-mirror` also
folds these notes into a "Known findings" section of
`.github/copilot-instructions.md` (below the sentinel) so Copilot can
answer from already-discovered findings; the *write* side is the manual
protocol in §2.
