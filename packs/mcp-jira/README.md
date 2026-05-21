# Pack: `mcp-jira`

Optional MCP server install. Adds Jira awareness to the agent — read
tickets by ID, search projects, surface acceptance criteria from inside
the conversation. Optional ticket-creation depending on the server's
scope.

Install when Jira is the team's ticket tracker and dev cycles regularly
reference Jira IDs (KYL-1234, PROJ-5678).

## What it gives the agent

- Look up a Jira ticket by key (`PROJ-1234`) — title, description,
  acceptance criteria, status, assignee, comments
- Search a Jira project with JQL — find tickets by sprint, label,
  status, etc.
- Surface ticket detail to the Triage role when work-shape is unclear
  from the prompt alone
- (Server permitting) Create / update / transition tickets — useful
  for PM-role post-cycle friction-bundle filing

## Setup

1. **Jira API token.** Generate at
   `https://id.atlassian.com/manage-profile/security/api-tokens`. Bound
   to your Atlassian identity; inherits your org access.
2. **Identify your Jira instance URL.** Usually `<your-org>.atlassian.net`
   for cloud, or a custom domain for self-hosted.
3. **Add to `.claude/env`:**
   ```
   export JIRA_URL=https://your-org.atlassian.net
   export JIRA_USER=your-email@your-domain.com
   export JIRA_API_TOKEN=ATATTxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
4. Run `bin/richardbot-init mcp jira` to add the server stanza and
   restart Claude Code.

## Verification

After install + restart, ask the agent: *"Get ticket PROJ-123."* — it
should fetch the ticket via the MCP rather than ask for the URL.

## Security notes

- The token grants the agent the same access you have. If you have
  admin rights, the agent does too.
- Atlassian API tokens have no scope-limiting on Cloud — they're
  all-or-nothing. For tighter scoping, create a service account with
  only the projects you want the agent to see.
- Rotate on the standard cadence (90 days or on suspected leak).

## When NOT to install

- Team uses Linear, GitHub Issues, ShortCut, Asana, or another tracker
  (each has its own MCP — install the right one instead)
- Read-only requirements are met by sharing the ticket URL in chat
  and letting the agent WebFetch it
- Compliance prohibits agent access to ticket bodies (some regulated
  environments)

## Composes with

`.claude/commands/triage.md` — Triage can resolve a ticket reference
in the work request before deciding cycle vs direct-dev vs exception.
`.claude/commands/pm.md` — PM can file post-cycle friction-bundle
items as tickets in the same dispatch.
