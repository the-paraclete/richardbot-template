# Pack: `mcp-aws`

Optional MCP server install. Adds AWS awareness to the agent — query
running resources, read CloudWatch logs, list S3 buckets / IAM users
/ ECS services from inside the conversation.

Install when the project deploys to AWS and the dev cycle needs to
verify live state during QA / deploy / postmortem stages.

**Security gravity:** highest of any MCP in this pack set. AWS
credentials grant whatever your role's policy allows. Read this
README in full before installing.

## What it gives the agent

- List resources across services — S3 buckets, EC2 instances, ECS
  services, Lambda functions, RDS instances
- Read CloudWatch logs at a time range for a given log group
- Inspect IAM policies (helpful during postmortem)
- (Server permitting) Run reads but never writes — most AWS MCPs
  default to read-only with a separate flag for write capability

## Setup

This pack uses **AWS SSO** as the canonical auth method (modern, no
long-lived access keys on disk). If your team uses static access keys
or OIDC, the setup differs — see the "Auth alternatives" section.

### SSO setup (recommended)

1. **Confirm your org has AWS IAM Identity Center (formerly AWS SSO)
   enabled.** If not, talk to your platform team before installing.
2. **Configure SSO in `~/.aws/config`** (init flow will write this):
   ```
   [sso-session your-org]
   sso_start_url = https://your-org.awsapps.com/start
   sso_region = us-east-1
   sso_registration_scopes = sso:account:access

   [profile your-project-staging]
   sso_session = your-org
   sso_account_id = 123456789012
   sso_role_name = ReadOnlyAccess
   region = us-east-1
   ```
3. **Sign in** (headed systems): `aws sso login --sso-session your-org`.
   On headless systems: `aws sso login --sso-session your-org --use-device-code`.
4. **Set the active profile** for the agent's MCP server:
   ```
   export AWS_PROFILE=your-project-staging
   ```
5. Run `bin/richardbot-init mcp aws` to add the server stanza and
   restart Claude Code.

### Auth alternatives

- **Static access keys** — `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`
  in `.claude/env`. Convenient but a real liability if leaked. Rotate
  every 90 days minimum; never commit; never paste in chat.
- **OIDC / IRSA** — workload identity for in-cluster agents. Not the
  shape this skeleton is designed for; configure manually.

## Verification

After install + restart and an active SSO session, ask the agent:
*"List S3 buckets in <region> under profile <profile>."* — should
work without further auth prompts.

## Security notes

- **Use a read-only role by default.** Most agent work doesn't need
  write — provision the SSO profile against `ReadOnlyAccess` or a
  custom read-only policy. Add write capability per-task with a
  separate profile if needed.
- **Never grant `AdministratorAccess`** to an agent's working profile.
  If a postmortem genuinely needs admin, escalate per your team's
  privileged-access flow — don't bake admin into the daily-driver.
- **SSO sessions expire** (default 8h). On expiry, the agent will
  start failing AWS calls; re-run `aws sso login` to refresh.
- **Audit the agent's AWS calls.** AWS CloudTrail logs every API
  call with the principal identity. Treat the agent like any other
  user — review periodically.
- **Account-scope mismatch is a foot-gun.** Verify the SSO profile
  is pointing at the right account before any cross-cutting read
  (especially with multi-account orgs where staging and prod are
  separate accounts).

## When NOT to install

- Project doesn't deploy to AWS
- Compliance requires that production AWS resources only be queried
  through audited shell sessions, not agent-mediated calls
- The team's AWS access is already brokered through a service
  catalog or PAM tool — adding an MCP would bypass that gate

## Composes with

`.claude/commands/qa.md` — QA can verify deploy state (ECS task
running, Lambda last invocation succeeded) without leaving the
cycle.
`.claude/commands/postmortem.md` — Postmortem can pull CloudWatch
logs from the incident window without manual export.
