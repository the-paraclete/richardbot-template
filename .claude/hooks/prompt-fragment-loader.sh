#!/usr/bin/env bash
# prompt-fragment-loader.sh — UserPromptSubmit hook.
#
# Scans .claude/rules/*.md frontmatter on every prompt; injects matching
# rule bodies into the turn's additionalContext.
#
# Three trigger types in rule frontmatter:
#   alwaysApply: true        — load on every turn
#   globs:       [pattern…]  — load when prompt mentions a path matching one
#   triggers.prompt: [tok…]  — load when prompt contains any (word-boundary)
#
# Fail-open: any error → exit 0 with no output. Never blocks the harness.
# Dependencies: bash, jq, grep, awk, cat. No python. No sqlite. Portable.

set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="${SCRIPT_DIR%/hooks}/rules"
MAX_RULES="${RICHARDBOT_MAX_RULES_PER_TURN:-5}"
MAX_BODY="${RICHARDBOT_MAX_BODY_CHARS:-4000}"
# Memory dir lives outside .claude/ (intentionally — to dodge the sensitive-file
# gate). The loader scans both rules + memory; memory entries get a [memory/]
# prefix in additionalContext so the agent knows they're agent-grown, not
# human-authored config.
MEMORY_DIR="${SCRIPT_DIR%/.claude/hooks}/.richardbot-memory"
MAX_MEMORY="${RICHARDBOT_MAX_MEMORY_PER_TURN:-3}"

[ -d "$RULES_DIR" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat)"
[ -z "$INPUT" ] && exit 0

PROMPT="$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)"
[ -z "$PROMPT" ] && exit 0
PROMPT_LC="$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')"

# ── Extract YAML frontmatter block from a markdown file ────────────────────
extract_frontmatter() {
  awk '
    BEGIN { open_seen = 0; in_fm = 0 }
    /^---[[:space:]]*$/ {
      if (!open_seen) { open_seen = 1; in_fm = 1; next }
      else if (in_fm) { exit }
    }
    in_fm { print }
  ' "$1"
}

# ── Extract a YAML list value (handles inline [a,b,c] and block - a / - b) ─
# Use a path like "triggers.prompt" or just "globs" — the parser looks for
# the LAST key in the path as a list owner inside the nearest matching block.
extract_yaml_list() {
  local fm="$1" path="$2"
  # Map dotted path to indented key search. Final key is the list owner.
  local final_key="${path##*.}"
  printf '%s\n' "$fm" | awk -v key="$final_key" '
    BEGIN { in_block = 0 }
    {
      # Match the key at any indent level, with optional inline list
      key_pat = "^[[:space:]]*" key ":[[:space:]]*"
      if (match($0, key_pat)) {
        rest = substr($0, RSTART + RLENGTH)
        # Inline list: key: [a, b, c]
        if (match(rest, /\[[^]]*\]/)) {
          gsub(/^\[|\][^]]*$/, "", rest)
          n = split(rest, parts, ",")
          for (i = 1; i <= n; i++) {
            v = parts[i]
            gsub(/^[[:space:]"\047]+|[[:space:]"\047]+$/, "", v)
            if (v != "") print v
          }
          in_block = 0
          next
        }
        in_block = 1
        next
      }
      if (in_block) {
        # Stop at any line that looks like a new top-level or peer key
        if (/^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*:/ && !/^[[:space:]]*-/) {
          in_block = 0
        } else if (/^[[:space:]]*-[[:space:]]+/) {
          v = $0
          sub(/^[[:space:]]*-[[:space:]]+/, "", v)
          gsub(/^[[:space:]"\047]+|[[:space:]"\047]+$/, "", v)
          if (v != "") print v
        }
      }
    }
  '
}

extract_yaml_scalar() {
  local fm="$1" key="$2"
  printf '%s\n' "$fm" | awk -v key="$key" '
    {
      pat = "^[[:space:]]*" key ":[[:space:]]*"
      if (match($0, pat)) {
        v = substr($0, RSTART + RLENGTH)
        gsub(/^[[:space:]"\047]+|[[:space:]"\047#]+$/, "", v)
        print v
        exit
      }
    }
  '
}

# Word-boundary case-insensitive token match in the prompt
prompt_contains_token() {
  local tok="$1"
  local lc="$(printf '%s' "$tok" | tr '[:upper:]' '[:lower:]')"
  local esc="$(printf '%s' "$lc" | sed 's/[][\\.^$*+?(){}|]/\\&/g')"
  printf '%s' "$PROMPT_LC" | grep -qE "(^|[^a-z0-9_])${esc}([^a-z0-9_]|\$)"
}

# Glob → prefix substring check (lightweight; PreToolUse hook does real path-glob)
prompt_mentions_glob_prefix() {
  local glob="$1"
  local prefix="$(printf '%s' "$glob" | sed 's/[*?{[].*$//')"
  [ -z "$prefix" ] && return 1
  local lc="$(printf '%s' "$prefix" | tr '[:upper:]' '[:lower:]')"
  printf '%s' "$PROMPT_LC" | grep -qF "$lc"
}

should_load_rule() {
  local file="$1" fm tok glob always
  fm="$(extract_frontmatter "$file")"
  [ -z "$fm" ] && return 1

  always="$(extract_yaml_scalar "$fm" "alwaysApply")"
  [ "$always" = "true" ] && return 0

  while IFS= read -r tok; do
    [ -z "$tok" ] && continue
    prompt_contains_token "$tok" && return 0
  done < <(extract_yaml_list "$fm" "triggers.prompt")

  while IFS= read -r glob; do
    [ -z "$glob" ] && continue
    prompt_mentions_glob_prefix "$glob" && return 0
  done < <(extract_yaml_list "$fm" "globs")

  return 1
}

MATCHED=()
shopt -s nullglob
for f in "$RULES_DIR"/*.md; do
  [ "${#MATCHED[@]}" -ge "$MAX_RULES" ] && break
  if should_load_rule "$f"; then
    MATCHED+=("$f")
  fi
done
shopt -u nullglob

# Memory walk — separate budget, separate label. Skip README and _recent.md
# (those aren't trigger-loaded entries; they're meta-files).
MATCHED_MEMORY=()
if [ -d "$MEMORY_DIR" ]; then
  shopt -s nullglob
  for f in "$MEMORY_DIR"/*.md; do
    base=$(basename "$f")
    case "$base" in README.md|_recent.md) continue ;; esac
    [ "${#MATCHED_MEMORY[@]}" -ge "$MAX_MEMORY" ] && break
    if should_load_rule "$f"; then
      MATCHED_MEMORY+=("$f")
    fi
  done
  shopt -u nullglob
fi

[ "${#MATCHED[@]}" -eq 0 ] && [ "${#MATCHED_MEMORY[@]}" -eq 0 ] && exit 0

OUT=$'[fragment-loader] Trigger matched; loading context:'
for f in "${MATCHED[@]}"; do
  name="$(basename "$f")"
  body="$(cat "$f")"
  if [ "${#body}" -gt "$MAX_BODY" ]; then
    body="${body:0:$MAX_BODY}"$'\n[…truncated; full file at .claude/rules/'"$name"']'
  fi
  OUT+=$'\n\n=== rule/'"$name"$' ===\n'"$body"
done
for f in "${MATCHED_MEMORY[@]}"; do
  name="$(basename "$f")"
  body="$(cat "$f")"
  if [ "${#body}" -gt "$MAX_BODY" ]; then
    body="${body:0:$MAX_BODY}"$'\n[…truncated; full file at .richardbot-memory/'"$name"']'
  fi
  OUT+=$'\n\n=== memory/'"$name"$' ===\n'"$body"
done

jq -nc --arg ctx "$OUT" \
  '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":$ctx}}'
exit 0
