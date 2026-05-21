---
description: The canonical dev cycle — Triage → Architect → Designer → Dev → Review → QA-tests → QA → UAT → Ship → Docs. Use the cycle for everything. Tests-first where possible. Review (opus) and QA gates are mandatory blocking.
alwaysApply: true
---

# The dev cycle

The canonical flow for any artifact-producing work in this repo. Each
stage has a role file in `.claude/commands/`; the dispatcher cats the
role file plus the task into a `claude --print --model <X>` subprocess.
Each role declares its own model.

## The flow

1. **Triage** (`triage`, haiku) — decide if the work is the full cycle,
   direct-to-Dev (mechanical), or an exception (typo/format/revert).
2. **Architect** (`architect`, opus) — designs surface shape. No code.
   Produces a plan doc that Dev executes against. Skipped for purely
   mechanical changes.
3. **Designer** (`designer`, opus) — interaction shape, when the work
   touches the UI. Skipped for backend-only changes.
4. **Dev** (`dev`, opus) — tests-first per the coverage discipline
   below, then code. Sonnet writes code poorly enough that the cycle
   uses opus as the default dev tier; retry-with-fresh-dispatch is the
   escalation pattern when a dev session is cut off (max-turns,
   0 bytes), not a separate junior seat.
5. **Review** (`review`, opus) — MANDATORY BLOCKING GATE. Reads the
   diff, catches the subtle-bug class (off-by-one, null-guards,
   type-coercion, scope decisions, security smells). FAIL → back to
   Dev. PASS → proceed.
6. **QA Tests** (`qa-tests`, sonnet) — MANDATORY BLOCKING GATE.
   Verifies the test suite is *meaningful* — not just passing. Catches
   rubber-stamp tests, missing edge coverage, stubs-pretending-to-be-
   behavior. FAIL → back to Dev. PASS → proceed.
7. **QA** (`qa`, sonnet) — MANDATORY BLOCKING GATE. Verifies the change
   actually works in running form. For UI / FE work, drives a real
   browser via Puppeteer; for backend / CLI, exercises the changed
   surface against real state. PASS / FAIL / NEEDS-REVISION / YELLOW
   (when a tool the verification needs isn't installed — UAT must
   then catch what QA couldn't).
8. **UAT** (manual, the operator) — human verification before ship.
   QA can't catch every interaction edge; UAT is where the operator
   actually uses the feature. Not a dispatched seat — this stage gates
   on a human's nod.
9. **Ship** (`ship`, sonnet) — commit, push, open PR with the body
   shape from `pr-flow.md`. Watches CI to green.
10. **Docs** (`docs`, sonnet) — updates anything the change made stale
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

## The gate layer — three blocking gates after Dev

After Dev ships work, three automated gates run in sequence before
human UAT:

- **Review** (opus) — does the *code itself* look correct? Subtle bugs,
  security, scope.
- **QA Tests** (sonnet) — does the *test suite* prove anything?
  Rubber-stamp tests fail this gate.
- **QA** (sonnet, +Puppeteer for FE) — does the *built thing* work
  end-to-end?

Each gate FAILs back to Dev with a file:line citation. PASS proceeds.
Per `gate-discipline.md`, gates surface ONLY blocking issues inline;
non-blocking polish goes to PM's post-cycle friction bundle.

## When Dev gets cut off

If Dev returns max-turns, 0 bytes, or diagnosis-only when fix was the
deliverable, the recovery pattern is **re-dispatch Dev with the partial
work as prior state**, not a separate "senior" seat. Both dispatches
run on opus; the second one reads `git status` and `git diff` first and
decides salvage vs. redo before writing.

## Tests where possible

Tests-first is the default. The bar is "every reasonable effort."
Surfaces that genuinely can't be unit-tested — browser-only APIs
without jsdom shims, third-party SDK side-effects, real network
calls — get an explicit waiver line in the PR body explaining why
the test wasn't written.

No skipping tests for convenience. "It was hard to test" is not a
waiver. (QA-tests will catch the meaningful-tests-are-missing case
on the next gate anyway.)

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

Each role file declares its own model in frontmatter.

For long-running dispatches, prefer backgrounded execution — the
dispatcher releases its window immediately, and the subprocess writes
its verdict to a known output path the dispatcher can poll.
