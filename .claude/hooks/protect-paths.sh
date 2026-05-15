#!/usr/bin/env bash
# protect-paths.sh - PreToolUse hook that blocks Edit/Write on sensitive paths.
# Reads tool_use JSON from stdin; emits allow/block JSON.
# Fail-open on parse failure.

set -euo pipefail
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || TOOL=""

# Only gate Edit/Write/MultiEdit tool calls.
case "$TOOL" in
  Edit|Write|MultiEdit) ;;
  *) echo '{"decision":"allow"}'; exit 0 ;;
esac

FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null) || FILE=""
[ -z "$FILE" ] && { echo '{"decision":"allow"}'; exit 0; }

block() {
  jq -nc --arg reason "$1" '{"decision":"block","reason":$reason}'
  exit 0
}

# Protected paths — agent should not modify these without explicit user direction.
case "$FILE" in
  *.env|*/.env|.env)
    block "Blocked: $FILE is an env/secrets file. Edit secrets manually, not via the agent." ;;
  */.git/*|*/.git)
    block "Blocked: $FILE is inside .git/. Use git commands, not direct edits." ;;
  */.claude/hooks/*)
    block "Blocked: $FILE is a framework hook. If you really want to edit it, do it manually — the agent shouldn't self-modify its own guardrails." ;;
  */.claude/settings.json)
    block "Blocked: $FILE is the framework settings file. Edit manually." ;;
  */CLAUDE.md)
    # CLAUDE.md is a user-edited spine; agent edits OK but warn loudly
    : ;;
esac

echo '{"decision":"allow"}'
