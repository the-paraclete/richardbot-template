---
description: General code-quality discipline — function size, nesting, parameters, naming, comments.
alwaysApply: true
---

# Code quality

## Naming

- **Booleans**: `is`/`has`/`should` prefix (`isActive`, `hasError`, `shouldRedirect`)
- **Handlers**: `on`/`handle` prefix (`onClick`, `handleSubmit`)
- **Descriptive over short.** `customerEligibleForGwp` > `eligible`. Avoid single-letter names except loop indices.

## Size limits

- **No function over 40 lines.** If it grows beyond, factor.
- **No nesting deeper than 3 levels.** Early-return / extract / dispatch instead.
- **No more than 3 parameters.** Use an options object for anything longer.

## Comments + commented-out code

- **No commented-out code.** Delete it; git remembers.
- **No `console.log` / `console.debug` / `console.warn`** in shipped code. Exceptions: explicit error-handling paths with reason.
- **No empty `catch {}` blocks.** If you intentionally swallow, comment why.
- **No `TODO:` without a ticket number.** `TODO(KYL-1234):` or no TODO.

## Duplication

- **No duplicate logic.** Check `src/vue/helpers/`, `src/vue/services/`, `src/vue/utilities/` for existing implementations before writing new.

## What to do when you find a violation

Flag in PR review with file:line. Don\'t merge with violations unsolved — either fix or explicitly waive with reviewer agreement.
