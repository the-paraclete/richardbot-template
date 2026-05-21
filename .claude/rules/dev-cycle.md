---
description: The canonical dev cycle — Triage → Architect → Designer → Dev → /review → QA → Ship → Docs. Use the cycle for everything. Tests-first where possible. /review (opus) is a mandatory blocking gate.
alwaysApply: true
---

# The dev cycle

The canonical flow for any artifact-producing work in this repo. Each
stage has a role file in `.claude/commands/`; the dispatcher cats the
role file plus the task into a `claude --print --model <X>` subprocess.
Each role declares its own model.

## The flow

1. **Triage** (`triage`, haiku/sonnet) — decide if the work is the full
   cycle or a one-liner. Routes to architect or directly to dev.
2. **Architect** (`architect`, opus) — designs surface shape. No code.
   Produces a plan doc that dev executes against. Skipped for purely
   mechanical changes.
3. **Designer** (`designer`, opus) — interaction shape, when the work
   touches the UI. Skipped for backend-only changes.
4. **Dev** (`dev`, sonnet) — tests-first per the coverage discipline
   below, then code. Default seat for new code.
5. **/review** (opus) — MANDATORY BLOCKING GATE. Opus reviewer catches
   subtle bugs Dev shipped. FAIL → back to Dev. PASS → proceed.
6. **QA** (`qa`, sonnet) — verifies the change actually works in
   running form, not just that tests pass. PASS / FAIL / NEEDS-REVISION.
7. **Ship** (`ship`, sonnet) — commit, push, open PR with the body
   shape from `pr-flow.md`. Watches CI to green.
8. **Docs** (`docs`, sonnet) — updates anything the change made stale
   (READMEs, CLAUDE.md, rule fragments, role files).

## The "everything" rule

**Any artifact-producing work runs the cycle.** Code changes, doc
changes, hook wiring, role-file edits, rule fragments. The cycle is
what catches the subtle-bug class that compiles green but ships wrong.

Exceptions are explicit and rare:

- One-character typos (e.g. fixing a single letter in a docstring)
- Pure-formatting changes a linter could have made
- Reverting an already-reviewed commit verbatim

Triage makes the exception call — Dev does not eyeball it.

## Two dev seats: Dev (sonnet) and Tech Lead (opus)

- **Dev** is the default seat. Cheap, fast, tests-first.
- **Tech Lead** is the senior seat. Same role contract, opus model.
  Takes over when Dev chokes.

Tech Lead is invoked automatically on any of these signals:

- Dev returned max-turns without a result
- Dev returned max-turns with partial work in the dev clone — Tech
  Lead salvages and completes from there
- Dev returned 0 bytes (silent fail / tool-loop deadlock)
- Dev returned diagnosis-only when fix was the deliverable
- Dev's tests pass but the code looks wrong on inspection

Tech Lead reads the dev-clone state first and finishes from there if
salvageable. Otherwise starts fresh on the same task.

## /review is mandatory and blocking

Every Dev-shipped change passes through `/review` (opus) before merge.
The opus reviewer catches the class of bugs Dev's model is prone to:

- Off-by-one indexing
- Missed null/undefined guards
- Type-coercion gotchas (`Number(true) === 1`, `"" == 0`, etc.)
- Misnamed identifiers that compile because they shadow something
- Scope decisions that look right but break a consumer

`/review FAIL` → back to Dev with the failure cited at file:line. No
merge until `/review PASS`.

## Tests where possible

Tests-first is the default. The bar is "every reasonable effort."
Surfaces that genuinely can't be unit-tested — browser-only APIs
without jsdom shims, third-party SDK side-effects, real network
calls — get an explicit waiver line in the PR body explaining why
the test wasn't written.

No skipping tests for convenience. "It was hard to test" is not a
waiver.

## Coverage discipline

**≥80% line coverage on changed files**, measured per-file, not
aggregate. The pre-commit hook enforces. PR body cites coverage delta
per file.

**Never report test counts.** Coverage % is the metric. "1416 tests
passing" / "all green" / "35 new tests added" — banned in PR bodies
and commit messages. Replace with `82% line coverage on src/foo/bar.js`
(the file, not the suite).

If code can't reach 80% coverage, refactor — most often the file is
doing too much or has a tight coupling to an untestable surface. Both
are fixable.

## How dispatch works

The dispatcher cats the role file plus the task into a `claude --print`
subprocess:

```sh
claude --print \
  --model "$(awk '/^model:/{print $2}' .claude/commands/dev.md)" \
  "$(cat .claude/commands/dev.md)

TASK: $TASK_DESCRIPTION"
```

Each role file declares its own model in frontmatter. Tech Lead
invocation is a separate dispatch with the same role contract but
`--model opus`, and the partial-work state from the prior Dev attempt
prepended to the task.

For long-running dispatches, prefer backgrounded execution — the
dispatcher releases its window immediately, and the subprocess writes
its verdict to a known output path the dispatcher can poll.
