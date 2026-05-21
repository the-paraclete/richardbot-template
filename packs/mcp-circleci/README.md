# Pack: `mcp-circleci`

Optional MCP server install. Adds CircleCI awareness to the agent —
inspect build status, fetch failure logs, find flaky tests, rerun
workflows, analyze pipeline diffs from inside the conversation.

Install only if CircleCI is the team's CI provider for this repo.

## What it gives the agent

- Read live pipeline status for the current branch
- Fetch build-failure logs at file:line — no manual log digging
- Find flaky tests across recent runs
- Analyze the diff between two pipelines
- Rerun a failed workflow without leaving the conversation
- List artifacts produced by a build
- Surface job test results in structured form

## Setup

1. **Create a CircleCI personal API token** at
   `https://app.circleci.com/settings/user/tokens`. The token is bound
   to your CircleCI identity; it inherits your org access.
2. **Choose scope.** The token grants the agent the same read/write
   abilities you have — including rerun-workflow. For read-only setups,
   provision a service-account token with minimum scopes instead.
3. **Add the token to your local `.claude/env`:**
   ```
   export CIRCLECI_TOKEN=CCIPAT_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
4. **Never commit the token.** `.env` and `.claude/env` are in the
   default `.gitignore`; verify before any commit.
5. Run `bin/richardbot-init mcp circleci` to add the server stanza to
   `.mcp.json` and restart Claude Code.

## Verification

After install + restart, ask the agent: *"What's the status of the
latest pipeline on this branch?"* — it should use a CircleCI MCP tool
rather than asking for the URL.

## Security notes

- Treat the CircleCI token as a secret with the same gravity as a
  production API key — it can rerun workflows, which can re-deploy.
- Rotate the token on any of: laptop loss, team-member offboarding,
  suspected leak in chat logs, or every 90 days as routine hygiene.
- If the agent's session transcript may be shared (paired sessions,
  recorded demos), use a per-session token and revoke after.

## When NOT to install

- Team uses GitHub Actions / Buildkite / Jenkins / something other
  than CircleCI as the primary CI provider
- Read-only requirements are met by `gh run list` + `gh run view`
  (GitHub Actions) — no need for a CircleCI MCP slot

## Composes with

`.claude/rules/pr-flow.md` — the PR-flow gate calls out "All required
CI checks green" before merge. With this MCP installed, the agent can
verify directly rather than asking you to paste the build URL.
