---
description: Secret handling — never commit, never log, never paste into chat or rules.
alwaysApply: true
---

# Secret handling

## Never commit

- `.env`, `.env.*` (except `.env.example` with placeholder values)
- API keys, OAuth tokens, password hashes, JWT secrets
- SSH keys (`id_rsa`, `id_ed25519`, any `*.pem`)
- AWS credentials (`.aws/credentials`, access key files)
- Database connection strings with embedded credentials
- Anything labeled "secret", "private", "token", "password"

## Never log / never echo

- Don\'t `echo $SECRET_VAR` in scripts or output
- Don\'t include secret values in error messages, traces, or test fixtures
- Don\'t paste secret values into chat (they get logged in your AI session)
- Don\'t paste secret values into rule fragments — they become part of every prompt that triggers the rule

## Use env vars + a secrets manager

- Local: a `.env` file (gitignored) loaded by your dev script
- CI: secrets stored in the CI system (GitHub Actions secrets, CircleCI env, etc.)
- Production: a real secrets manager (AWS Secrets Manager, GCP Secret Manager, Vault, Doppler, etc.)
- Rotate on compromise; assume any committed secret IS compromised

## If you accidentally commit a secret

1. **Treat it as leaked** — even if you force-push to remove it. Public repos are scraped within seconds; private repos can leak through forks, CI logs, or local clones.
2. **Rotate the secret immediately** at the source (regenerate the API key, etc.).
3. **Document the incident** as a postmortem in `.richardbot-memory/`.
4. **Don\'t rely on `git filter-branch` or BFG** as the recovery — the secret was visible the moment it was pushed.

## How the framework helps

- `block-destructive.sh` blocks truncation of `.env` and similar files via `>` redirect
- `protect-paths.sh` blocks Edit/Write tool calls on `.env` files
- These are belt-and-suspenders — your discipline is still the primary defense
