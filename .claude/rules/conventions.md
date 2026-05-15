---
description: Always-loaded coding + commit + PR conventions for this repo.
alwaysApply: true
---

# Conventions

## Coding

- Tests-first. New code lands with tests; coverage on changed files ≥85%
  on lines / statements / functions. Branch coverage is best-effort.
- Run the full suite before declaring done. Don't quote test counts —
  coverage is the metric.
- Read the file end-to-end before editing it. Don't paraphrase from a grep.
- One topic per commit. Smallest reversible unit.

## Commits

- Format: `<type>(<scope>): <imperative summary>` — `feat`, `fix`,
  `chore`, `test`, `docs`, `refactor`.
- Body explains the *why* in the team's vocabulary. Engineering
  rationale, not process-internal references.
- No agent-specific footers in user-facing commit messages.

## PRs

- Title under 70 chars. Details in the body.
- Sections: Summary / Why / What changed / Test plan.
- Test plan includes coverage delta on changed files and a manual
  verification checklist for behavior the suite doesn't catch.
- Pull main before push. Rebase if behind.

## Don't

- Don't ship code with `console.log`, debug prints, or commented-out blocks.
- Don't widen scope mid-PR. File a follow-up and stay narrow.
- Don't force-push shared branches without coordinating.
