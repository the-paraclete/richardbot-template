#!/usr/bin/env bash
# session-orient.sh - SessionStart hook. Emits a brief turn-start summary.
# Reads no input (SessionStart fires once); writes additionalContext to stdout.

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" || exit 0

branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo '(detached)')"
dirty="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
recent="$(git log --oneline -5 2>/dev/null || true)"

prs=""
if command -v gh >/dev/null 2>&1; then
  prs="$(gh pr list --state open --limit 5 --json number,title,headRefName 2>/dev/null \
         | jq -r '.[] | "  #\(.number) [\(.headRefName)] \(.title)"' 2>/dev/null || true)"
fi

ctx=$'## Session orient\n'
ctx+="- Branch: $branch ($dirty dirty file(s))"$'\n'
ctx+="- Recent commits:"$'\n'"$(printf '%s\n' "$recent" | sed 's/^/  /')"$'\n'
if [ -n "$prs" ]; then
  ctx+="- Open PRs:"$'\n'"$prs"$'\n'
fi

# Surface .richardbot-memory/_recent.md tail if present
if [ -f .richardbot-memory/_recent.md ]; then
  recent_mem="$(tail -10 .richardbot-memory/_recent.md 2>/dev/null | head -5)"
  if [ -n "$recent_mem" ]; then
    ctx+="- Recent memory:"$'\n'"$(printf '%s\n' "$recent_mem" | sed 's/^/  /')"$'\n'
  fi
fi

jq -nc --arg c "$ctx" '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$c}}'
