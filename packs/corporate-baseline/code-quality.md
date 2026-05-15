---
description: Code-quality discipline — function size, nesting, parameters, naming, comments. Stack-agnostic.
alwaysApply: true
---

# Code quality

## Naming

- **Booleans**: `is`/`has`/`should` prefix — `isActive`, `hasError`, `shouldRedirect`. Predicates read like sentences.
- **Handlers**: `on`/`handle` prefix — `onClick`, `handleSubmit`.
- **Descriptive over short.** `customerEligibleForPromotion` > `eligible`. Avoid single-letter names except loop indices.
- **No abbreviations that need a glossary.** `req`/`res`/`ctx` are conventions; `cep`/`stp`/`qpc` are puzzles.

## Size limits

- **No function over 40 lines.** If it grows beyond, factor — extract a helper, split branches.
- **No nesting deeper than 3 levels.** Early-return / extract / dispatch table instead of building pyramids.
- **No more than 3 positional parameters.** Use an options object for anything longer (`fn({ a, b, c, d })`).

## Comments + commented-out code

- **No commented-out code in shipped diffs.** Delete it; git remembers.
- **No `console.log` / `console.debug` / `console.warn`** in production paths. Exception: explicit `console.error` inside a `catch` block with a reason.
- **No empty `catch {}` blocks.** If you intentionally swallow, comment why and at minimum log `console.error(err)`.
- **No bare `TODO:` without a ticket reference.** Either `TODO(PROJ-1234): description` or no TODO. Unreferenced TODOs accumulate forever and signal nothing.

## Duplication

- **Check existing helpers / utilities / services before writing new.** Most codebases have a `lib/`, `utils/`, `helpers/`, or `services/` directory — search it before adding a fresh implementation of the same primitive.
- **Three-strikes rule.** Two duplicates are tolerable; three means it's time to factor.

## Imports & dead code

- **No unused imports.** Most linters catch this; if yours doesn't, audit by hand.
- **No dead code paths.** If a branch is unreachable, delete it. If it's reachable only via a flag that's permanently off, delete the flag and the branch.

## What to do when you find a violation

Flag in PR review with file:line. Don't merge with violations unsolved — either fix in the same PR or explicitly waive with reviewer agreement and a follow-up ticket.

## Verify

- Run the project's linter before push (`npm run lint`, `flake8`, `golangci-lint`, whatever applies).
- Grep the diff for `console.log`, `TODO:` (without `(TICKET-`), `// eslint-disable` (any disable comment needs a reason in the same line).
- Visual: function-size and nesting can't be linted reliably — read the diff and flag violations in review.
