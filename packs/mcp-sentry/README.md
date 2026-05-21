# Pack: `mcp-sentry`

Optional MCP server install. Adds Sentry awareness to the agent — pull
error events by ID, list issues for a project, surface stack traces and
breadcrumbs without leaving the conversation.

Install when the project ships errors to Sentry and the dev cycle needs
to link a code change to its production error signal.

## What it gives the agent

- Look up a Sentry issue by ID, project, or recent-events query
- Read full event payload — exception type, stack trace, breadcrumbs,
  user context, release tag
- Surface issues affecting a specific release the agent is about to ship
- Cross-reference an issue's first-seen / last-seen with a PR's deploy
  timestamp for "did this PR cause this error?" analysis
- (Server permitting) Resolve / ignore / reopen issues post-fix

## Setup

1. **Sentry account + Internal Integration token.** In your Sentry org:
   Settings → Developer Settings → Internal Integration → New
   Internal Integration. Scope it to:
   - Issue & Event: Read (minimum)
   - Issue & Event: Write (if you want the agent to resolve issues)
   - Project: Read
2. **Copy the auth token** (starts with `sntrys_…` or similar).
3. **Add to `.claude/env`:**
   ```
   export SENTRY_AUTH_TOKEN=sntrys_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   export SENTRY_ORG=your-org-slug
   ```
4. Run `bin/richardbot-init mcp sentry` to add the server stanza and
   restart Claude Code.

## Verification

After install + restart, ask the agent: *"List the top 5 unresolved
issues for project <name> in the last 24 hours."* — it should use a
Sentry MCP tool rather than asking for a URL.

## Security notes

- The auth token has org-wide read access. Treat as a secret.
- Internal integration tokens cannot be rotated automatically — if
  you need to revoke, delete the integration and recreate.
- Avoid pasting raw event payloads into chat logs that might be
  shared — they can contain PII from user context.

## When NOT to install

- Team doesn't use Sentry (or uses a competitor — Honeybadger, Bugsnag,
  Rollbar — that has its own MCP)
- Read-only requirements are met by the Sentry web UI + manual paste
- Privacy concerns about Sentry event payloads being agent-readable
  override the productivity gain

## Composes with

`.claude/commands/postmortem.md` — the postmortem role can correlate
issue first-seen timestamps with deploy markers to identify root-cause
deploys without manual log diving.
