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
