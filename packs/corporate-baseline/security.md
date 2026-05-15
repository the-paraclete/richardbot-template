---
description: Security baseline — no secrets in source, no PII in inline scripts, sanitize before rendering.
alwaysApply: true
---

# Security baseline

## No secrets in source

- **No API keys, OAuth tokens, JWTs, DB passwords, or signing secrets** in template files, JS source, config files, or commit messages.
- **No `.env` files committed** (except `.env.example` with placeholder values).
- **No hardcoded production URLs containing credentials** (e.g., `https://user:pass@db.example.com`).

If you see one in a diff: stop, rotate the secret at the source, scrub from git history, document the incident.

## No PII in inline `<script>` tags

Inline scripts that interpolate customer data become XSS vectors AND PII-leak surfaces:

```liquid
<!-- DON'T -->
<script>
  window.__USER__ = {{ customer | json }};
</script>
```

If a hostile reflected-input lands in `customer.first_name`, that's stored XSS. Even without an attacker, the page source now contains the customer's email / address / phone in plain text — accessible to any third-party script on the page, any browser extension, any "view source" copy.

**Use instead:**
- `data-*` attributes on a server-rendered element, hydrated by JS that reads + immediately removes the data.
- A separate authenticated API call from the SPA layer.
- A `<script type="application/json">` block with a known id, parsed by JS — content is not executed, but it's still in the page source, so still don't put PII there.

## Sanitize before rendering

Any content sourced from CMS, user input, third-party API, or URL parameters must be sanitized before rendering as HTML:

| Source | Risk | Mitigation |
|---|---|---|
| User input rendered as HTML | Stored XSS | DOMPurify (or framework equivalent) before binding |
| URL params reflected into page | Reflected XSS | `encodeURIComponent` for attribute values; escape for HTML text |
| CMS-authored rich text | Stored XSS | Sanitize at render time, even if author is "trusted" |
| Third-party API responses | Supply-chain XSS | Treat as untrusted; sanitize what hits the DOM |

**Framework-specific:**
- Vue: no `v-html` without sanitization. Prefer `v-text` or `{{ }}` interpolation.
- React: `dangerouslySetInnerHTML` requires sanitization; the API name is the warning.
- Liquid/Handlebars: use the framework's escaping default (`{{ value }}`), not the raw-output variant (`{{{ value }}}`, `{% raw %}`).

## CSP headers, where applicable

If the project ships a CSP:
- Don't relax `script-src` to `unsafe-inline` just to make an inline script work — refactor the script to external.
- Nonces are fine if the build pipeline can generate them.

If the project doesn't yet ship a CSP, plant a follow-up ticket — don't shipping new inline scripts in projects that will need a CSP later.

## Authentication & authorization

- Never trust client-supplied `customer_id`, `user_id`, `is_admin`, etc. — verify on the server.
- Don't put authorization decisions in client-side JS (anyone can edit it).
- Rate-limit endpoints that touch payment, account modification, password reset.

## Verify

- Grep the diff for `dangerouslySetInnerHTML`, `v-html`, `innerHTML =`, `document.write` — any new occurrence needs a sanitizer.
- Grep for `{{ customer`, `{{ user`, `{{ order` inside `<script>` tags — flag for inline-PII removal.
- Run a secret-scanner (gitleaks, trufflehog) on the diff before push.
- If the project has CSP: confirm new inline scripts have nonces, not `unsafe-inline` relaxations.
