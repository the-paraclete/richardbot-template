# Packs

Opinionated rule fragment bundles for specific stacks. The baseline
template ships universal rules in `.claude/rules/` (conventions, secrets,
pr-flow, client-repo). **Stack-specific discipline lives in packs** so
that consumers only load what applies to their codebase.

## Available packs

- **`shopify-theme`** — Shopify Online Store 2.0 themes (Liquid + Vue 3 +
  Tailwind + ITCSS + Shopify Cart API). Reviewer-grade discipline derived
  from production-team review criteria.

## How packs work

Each pack is a directory under `packs/<name>/` containing:

- `README.md` — what this pack covers + which stack it's for
- One or more `.md` rule fragments with frontmatter triggers

When a consumer installs the pack, the fragments get copied into the
target repo's `.claude/rules/`. The fragment-loader hook then surfaces
them on matching prompts, same as any other rule. **No new mechanism**
— packs are just an opinionated set of rule files curated for a stack.

## Installing a pack

```sh
# At init time:
richardbot-init init --pack shopify-theme

# Or add to an existing install:
richardbot-init pack add shopify-theme

# List installed packs:
richardbot-init pack list

# Remove a pack (preserves any of its rules you've edited):
richardbot-init pack remove shopify-theme
```

## Authoring a new pack

1. Create `packs/<your-stack>/`
2. Write a `README.md` explaining what it covers
3. Add `.md` rule fragments with appropriate frontmatter triggers (see
   `../.claude/rules/README.md` for the rule shape)
4. Test with `richardbot-init pack add <your-stack>` on a sample repo
5. Document expected triggers and which surfaces it applies to

Packs version with the template itself. A breaking pack change should
bump the template version.
