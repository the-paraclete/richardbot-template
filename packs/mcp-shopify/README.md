# Pack: `mcp-shopify`

Optional MCP server install. Adds Shopify dev-tooling capabilities to the
agent — search the Shopify Admin / Storefront / Functions API docs from
inside the conversation, validate GraphQL queries against the schema,
verify theme syntax, search the Shopify dev docs.

Install only if this repo is a Shopify project (theme, app, function,
or Storefront integration).

## What it gives the agent

- Search Shopify's GraphQL Admin / Storefront / Functions schemas without
  WebFetch — fast doc lookups during dev cycles
- Validate GraphQL queries against the current API version before they
  ship
- Validate Liquid theme code blocks
- Search the Shopify dev docs corpus
- Validate Shopify UI extension component codeblocks

## Setup

1. **No Shopify-side account required.** This is a public dev-tooling MCP;
   it reads from Shopify's public docs and schema introspection. No token
   needed in the default install.
2. The `richardbot-init mcp shopify` flow adds the server stanza to
   `.mcp.json` and reminds you to restart Claude Code so the MCP loads.
3. **If you ALSO want live shop access** (read products, run admin
   mutations against a real store), that's a SEPARATE token-bearing MCP
   server — not this pack. Add it manually per your team's secret-handling
   discipline.

## Verification

After install + restart, the agent should have access to tools whose names
begin with `mcp__shopify-dev__` (or similar — exact prefix depends on the
server's `name` field). Ask the agent: *"validate this GraphQL query
against the Shopify Admin 2026-04 schema: <query>"* — it should use the
MCP tool rather than WebFetch.

## When NOT to install

- Repo is not a Shopify project
- You only need occasional doc lookups (WebFetch suffices; no need to
  hold an MCP slot)
- You're hitting per-session MCP limits and need to free slots for more
  critical servers

## Composes with

`packs/shopify-theme/` — the Shopify-theme code-review pack. Both
co-installed is the typical shape for a theme repo. The pack provides
authored review criteria; this MCP provides live schema validation.
