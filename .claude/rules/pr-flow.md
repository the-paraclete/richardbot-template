---
description: PR-flow conventions — review gates, merge policy, rebase posture, no-internal-context-in-PR-bodies.
alwaysApply: false
triggers:
  prompt:
    - "PR"
    - "pull request"
    - "merge"
    - "review"
    - "rebase"
    - "force push"
    - "gh pr"
---

# PR flow

## Before opening a PR

1. **Work in a dev clone**, not your production checkout. If your team uses `~/work/<repo>/` for active development and `~/code/<org>/<repo>/` for the running prod copy, follow that convention.
2. **Branch off `origin/main`** after `git fetch`. Never branch off a stale local main.
3. **Test locally** — the full suite, not just changed-file tests. If the suite is slow, use whatever fast-feedback subset your team has agreed on, then run the full suite before push.
4. **Run the linter / formatter** that CI runs. PRs that fail lint waste reviewer time.

## Before push

- **Pull main, rebase if behind.** A PR opened on a stale base loses context fast.
- **Force-push only your own feature branches**, never shared or `main`. Prefer `--force-with-lease` to plain `--force`.
- **No secrets in commits.** Run a secret scanner if your team has one. Never `git add .env` or anything that looks like a credential.

## PR body shape

- **Summary** (1–3 sentences): what changed, in plain engineering vocabulary.
- **Why**: the reason — link to a ticket / Jira / GH issue if applicable.
- **What changed**: bullet list of files/modules + one-line purpose each. Be specific.
- **Test plan**: what you ran, what you verified, what remains for manual UAT.
- **NO internal process references** — no agent-internal seed names, no role names, no internal memory artifacts. Engineering rationale in the reviewer\'s vocabulary, period.

## Merge gates (configure per-team; defaults below)

A PR is NOT ready to merge until:

- [ ] **All required CI checks green** (test suites, lint, build, type-check, lighthouse / perf budget if applicable)
- [ ] **Copilot review** (or equivalent automated reviewer) has no unresolved comments — either no comments OR every comment has been addressed in a follow-up commit with a reply explaining the fix
- [ ] **At least one human reviewer approval** (raise the floor to two on framework / shared-lib changes)
- [ ] **Branch is up-to-date with target** — rebase or merge main before merging out

## After merge

- Delete the feature branch (most teams auto-delete via repo settings)
- Update any tickets / linked issues
- Watch the next deploy in case the change interacts with prod state

## Don\'t

- Don\'t `merge` if any required check is red — fix or revert before merging
- Don\'t skip Copilot review if your team requires it ("I read it, looks fine" is not the same gate)
- Don\'t squash-merge a PR that contains separate logical changes — they belong in separate PRs
- Don\'t include AI-generated commit attribution footers in user-facing PR bodies (commit messages with attribution are fine for traceability; PR body is operator-facing)
