#!/usr/bin/env bash
# block-destructive.sh - PreToolUse(Bash) hook for the richardbot template.
#
# Blocks dangerous bash commands that an agent (or a human-driving-an-agent)
# should not run without explicit user confirmation. Reads PreToolUse JSON
# from stdin; emits decision JSON to stdout. Fail-open on parse error.

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || CMD=""

if [ -z "$CMD" ]; then
  echo '{"decision":"allow"}'
  exit 0
fi

block() {
  jq -nc --arg reason "$1" '{"decision":"block","reason":$reason}'
  exit 0
}

# Recursive force-delete (rf or fr flag combinations).
if echo "$CMD" | grep -qP '\brm\s+(-[a-z]*r[a-z]*f[a-z]*|-[a-z]*f[a-z]*r[a-z]*)\s'; then
  TARGETS=$(echo "$CMD" | grep -oP '\brm\s+(-[a-z]*r[a-z]*f[a-z]*|-[a-z]*f[a-z]*r[a-z]*)\s+\K.*')
  DOMINATED_BY_SAFE=true
  for TARGET in $TARGETS; do
    if [[ "$TARGET" == -* ]]; then continue; fi
    case "$TARGET" in
      node_modules|*/node_modules|./node_modules) continue ;;
      /tmp|/tmp/*) continue ;;
      .cache|*/.cache|./.cache) continue ;;
      dist|*/dist|./dist|build|*/build|./build) continue ;;
    esac
    DOMINATED_BY_SAFE=false
    break
  done
  if [ "$DOMINATED_BY_SAFE" = false ]; then
    block "Blocked: recursive force-delete to an unsafe path. Allowed only on node_modules, /tmp/*, .cache, dist/, build/."
  fi
fi

# Recursive delete on protected directories.
if echo "$CMD" | grep -qP '\brm\s+(-[a-z]*r[a-z]*)\s'; then
  if echo "$CMD" | grep -qP '\brm\s+-[a-z]*r[a-z]*\s+[^\s]*\b(\.claude|\.richardbot-memory|src|lib|tests?|spec)/'; then
    block "Blocked: recursive delete on protected dir (.claude/, .richardbot-memory/, src/, lib/, tests/, spec/)."
  fi
fi

# git reset --hard
if echo "$CMD" | grep -qP 'git\s+reset\s+--hard'; then
  block "Blocked: git reset --hard destroys uncommitted work. Use git stash or commit first."
fi

# git checkout -- . / git checkout .
if echo "$CMD" | grep -qP 'git\s+checkout\s+--\s+\.'; then
  block "Blocked: git checkout -- . discards all uncommitted changes."
fi
if echo "$CMD" | grep -qP 'git\s+checkout\s+\.\s*($|[;&|])'; then
  block "Blocked: git checkout . discards all uncommitted changes."
fi

# git clean -f
if echo "$CMD" | grep -qP 'git\s+clean\s+-[a-z]*f'; then
  block "Blocked: git clean -f deletes untracked files permanently."
fi

# git push --force / -f
if echo "$CMD" | grep -qP 'git\s+push\s+.*--force'; then
  block "Blocked: git push --force can destroy remote history. Consider --force-with-lease."
fi
if echo "$CMD" | grep -qP 'git\s+push\s+.*\s-f(\s|$)' || echo "$CMD" | grep -qP 'git\s+push\s+-f(\s|$)'; then
  block "Blocked: git push -f can destroy remote history. Consider --force-with-lease."
fi

# Truncation of critical files via > redirect.
if echo "$CMD" | grep -qP '>\s*(CLAUDE\.md|README\.md|\.claude/settings\.json|package-lock\.json|yarn\.lock|pnpm-lock\.yaml)'; then
  block "Blocked: truncating a critical project file via redirect. Use Edit/Write tools."
fi

echo '{"decision":"allow"}'
