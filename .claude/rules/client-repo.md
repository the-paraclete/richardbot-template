---
description: Client-repo discipline — token handling, audience-appropriate PR bodies, "/work/ not /code/" cloning, no-internal-context.
alwaysApply: false
triggers:
  prompt:
    - "client repo"
    - "client PR"
    - "third-party repo"
    - "external repo"
    - "vendor"
    - "shopify shop"
---

# Client / external-repo discipline

When working in a repo that is NOT your own team\'s, additional rules kick in.
This fragment is the generic shape; if your team has a specific repo with its
own discipline (e.g., `acmecorp/*`, `bigclient/*`), copy this and tighten the
specifics into a per-client rule.

## 1. Auth — use the right account for that org

Most teams have multiple GitHub accounts (personal, client A, client B). The
default active account is whatever you logged in last. Client orgs you don\'t
own will return `Repository not found` if the wrong token is active — that is
NOT a "creds are broken" error; it\'s "wrong identity is being tried."

For one-off git ops without mutating global state:

```sh
TOKEN=$(gh auth token -u <client-account-name>)
git -C <repo> -c credential.helper= fetch \
  "https://x-access-token:${TOKEN}@github.com/<client-org>/<repo>.git" \
  main:refs/remotes/origin/main
```

For `gh` CLI ops:

```sh
GH_TOKEN=$(gh auth token -u <client-account-name>) gh pr create ...
```

**Never `gh auth switch` globally** — it breaks parallel agents in other shells.

## 2. Work clone vs production checkout

If your team distinguishes between dev clones and running-prod checkouts (common
pattern: `~/work/<repo>/` for dev, `~/code/<org>/<repo>/` for the running copy),
**do dev work in `/work/`**. Production checkouts may have local state, branches,
or modifications that should not be touched by routine dev work.

## 3. PR body audience

Client-repo PRs go to **the client team**, not your own. That means:

- **No internal process artifacts** in the PR body or commit messages: no
  references to your team\'s memory system, internal seed names, role-files,
  wikilinks, lease primitives, or paraclete/agent terminology.
- **Engineering vocabulary only.** Explain the *why* in terms the client team
  uses (their ticket numbers, their architecture vocabulary, their conventions).
- **Verbatim user quotes** that mention internal-team context get rewritten as
  engineering rationale or removed.
- **No AI attribution in PR body** — commit-message trailer is fine for
  traceability, PR body is operator-facing and stays clean.

## 4. Merge gates

Client repos often have stricter gates than your own:

- **Automated reviewer (Copilot, sourcery, codacy, etc.)** must have no
  unresolved comments — either no comments OR every comment addressed in a
  follow-up commit + reply
- **CI (CircleCI, GH Actions, Buildkite, etc.)** must be fully green —
  test_deploy, build, lint, security scan, perf budgets where they exist
- **Human reviewer approval** from someone on the client team
- **Branch up-to-date with target** — rebase or merge target before merging out

Don\'t merge if any gate is red. "I think this is fine" is not the same as the
gate passing.

## 5. Pull main before push (every time)

A PR opened on a stale base loses context. Before push:

```sh
git fetch <client-remote> main
git rev-list --left-right --count HEAD...<client-remote>/main   # "X Y" → X ahead, Y behind
git rebase <client-remote>/main                                  # if Y > 0
# re-run tests after rebase
```

If you already pushed and now need to update: `--force-with-lease` (not plain
`--force`), with the explicit SHA you expect to overwrite.

## 6. Coverage discipline

Most client teams have coverage thresholds (often 80% or 85% on changed files
for lines/statements/functions). Run with `--coverage` and verify before
declaring done. Never report test counts to the team; report coverage delta.
