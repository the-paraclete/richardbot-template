# Packs

Two kinds of opinionated bundles, each addressing one slice of "what
this consumer's codebase needs that the baseline doesn't ship."

- **Stack packs** — rule-fragment bundles for a specific framework
  (Shopify, Next.js, etc.). Drop into `.claude/rules/` of the target
  repo; the fragment-loader hook surfaces them on matching prompts.
- **MCP packs** — server-config templates + setup docs for optional
  MCP integrations (Shopify-dev, CircleCI, Sentry, Jira, Slack, AWS).
  Each adds a stanza to `.mcp.json` so the agent gains the
  corresponding tool surface.

The baseline template ships universal rules in `.claude/rules/`
(conventions, secrets, pr-flow, client-repo, dev-cycle, gate-discipline).
Packs are what consumers opt into per-project.

## Available stack packs

- **`shopify-theme`** — Shopify Online Store 2.0 themes (Liquid + Vue 3 +
  Tailwind + ITCSS + Shopify Cart API). Reviewer-grade discipline derived
  from production-team review criteria.

## Available MCP packs

- **`mcp-shopify`** — Shopify dev-tooling (GraphQL schema validation,
  doc search, Liquid validation). No token required.
- **`mcp-circleci`** — CircleCI pipeline access (build status, failure
  logs, flaky tests, rerun). Requires `CIRCLECI_TOKEN`.
- **`mcp-sentry`** — Sentry error tracking (issue lookup, event
  payloads, breadcrumbs). Requires `SENTRY_AUTH_TOKEN`.
- **`mcp-jira`** — Jira ticket access (read, search, optional create).
  Requires `JIRA_API_TOKEN`.
- **`mcp-slack`** — Slack messaging (post, read channels). Requires
  `SLACK_BOT_TOKEN`.
- **`mcp-aws`** — AWS resource queries (S3, EC2, CloudWatch, IAM).
  Uses SSO via `AWS_PROFILE` (recommended) or static keys.

Each MCP pack's `README.md` documents what it gives the agent, how
to provision the token, security gravity, and when not to install.

## How stack packs work

Each is a directory under `packs/<name>/` containing:

- `README.md` — what this pack covers + which stack it's for
- One or more `.md` rule fragments with frontmatter triggers

When a consumer installs the pack, the fragments get copied into the
target repo's `.claude/rules/`. The fragment-loader hook then surfaces
them on matching prompts, same as any other rule. **No new mechanism**
— packs are just an opinionated set of rule files curated for a stack.

## How MCP packs work

Each is a directory under `packs/<name>/` containing:

- `README.md` — what the MCP gives the agent, how to provision auth,
  security gravity, verification, when not to install

The actual server stanzas live in `.mcp.json.template` at the repo
root. The `richardbot-init mcp` flow prompts per-server, collects
the env-var values, writes a filtered `.mcp.json` to the target repo,
and reminds the operator to restart Claude Code.

MCP packs don't ship rule fragments — they ship integration. They can
be co-installed with stack packs; for a Shopify theme repo, the typical
shape is `shopify-theme` (stack) + `mcp-shopify` (live schema lookup) +
`mcp-circleci` (CI awareness).

## Installing a pack

```sh
# Stack pack at init time:
richardbot-init init --pack shopify-theme

# Add a stack pack to an existing install:
richardbot-init pack add shopify-theme

# Install an MCP pack (interactive — prompts for keys):
richardbot-init mcp circleci

# Install multiple MCP packs at once:
richardbot-init mcp shopify circleci sentry

# List installed packs (both kinds):
richardbot-init pack list

# Remove a stack pack (preserves any rules you've edited):
richardbot-init pack remove shopify-theme

# Remove an MCP pack (removes the .mcp.json stanza; preserves .claude/env):
richardbot-init mcp remove circleci
```

## Authoring a new stack pack

1. Create `packs/<your-stack>/`
2. Write a `README.md` explaining what it covers
3. Add `.md` rule fragments with appropriate frontmatter triggers (see
   `../.claude/rules/README.md` for the rule shape)
4. Test with `richardbot-init pack add <your-stack>` on a sample repo
5. Document expected triggers and which surfaces it applies to

## Authoring a new MCP pack

1. Create `packs/mcp-<service>/`
2. Write a `README.md` covering: what the MCP gives the agent, setup
   (account, token, scopes), env-var slots, verification step, security
   gravity, when not to install, composes-with notes
3. Add a stanza to `.mcp.json.template` at the repo root with
   placeholder env-var references
4. Update `bin/richardbot-init mcp` to handle the per-server prompt
   flow if env vars are required
5. Test on a sample repo end-to-end (token in, MCP loaded, tool calls
   work)

Packs version with the template itself. A breaking pack change should
bump the template version.
