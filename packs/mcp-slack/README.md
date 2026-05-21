# Pack: `mcp-slack`

Optional MCP server install. Adds Slack awareness to the agent — post
messages to channels, read recent threads, surface deploy / on-call /
PR-review pings from inside the conversation.

Install when Slack is the team's primary chat surface and the dev
cycle's Ship stage needs to notify a channel post-merge or post-deploy.

## What it gives the agent

- Post a message to a named channel (PR opened, deploy started, etc.)
- Read recent messages in a channel — context-pull from a deploy
  channel or an oncall channel
- DM a teammate with a status update (within bot's permissions)
- Surface unread mentions when the agent's user has them
- (Server permitting) React to a message, edit a previous bot
  message, upload a file

## Setup

1. **Create a Slack App** at `https://api.slack.com/apps`. The app
   represents the bot identity that will post to channels.
2. **Add OAuth scopes** in the app config:
   - `chat:write` (post messages)
   - `channels:read` (list channels by name)
   - `channels:history` (read recent messages — only if you want
     read-channel capability)
   - `users:read` (resolve mentions to usernames)
3. **Install the app to your workspace.** Copy the Bot User OAuth
   Token (starts with `xoxb-`).
4. **Invite the bot to relevant channels** — Slack apps only see
   channels they're explicitly added to. `/invite @your-bot-name`.
5. **Add to `.claude/env`:**
   ```
   export SLACK_BOT_TOKEN=xoxb-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   export SLACK_DEFAULT_CHANNEL=deploys
   ```
6. Run `bin/richardbot-init mcp slack` to add the server stanza and
   restart Claude Code.

## Verification

After install + restart, ask the agent: *"Post a test message to
#<channel> saying 'mcp-slack hooked up'."* — message should appear in
the channel from the bot's identity.

## Security notes

- The bot token grants the bot's permissions to whoever holds it. Don't
  paste it into any agent-shared context.
- Use scoped tokens. `chat:write` alone is sufficient for outbound
  notifications; only add `channels:history` if you need read access.
- Slack workspace admins can audit bot activity — message-posting is
  visible in the workspace audit log. Posting volume should be modest
  (one message per cycle stage, not chatty real-time updates).
- Avoid posting full PR diffs or code contents to public channels —
  use deploy-notification shape, not paste-bin shape.

## When NOT to install

- Team uses Discord, Teams, or another chat tool (each has its own MCP)
- Team has Slack but doesn't want bot-shaped automation posting
  (cultural fit matters)
- Notifications are already handled by GitHub's Slack integration or
  CI's deploy-notify plugin — no need for agent-side posting

## Composes with

`.claude/commands/ship.md` — Ship can post a "PR opened: <URL>" or
"deploy started: <release>" message to a designated channel as part
of the ship stage.
