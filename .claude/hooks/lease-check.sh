#!/usr/bin/env bash
# lease-check.sh - report status of one or all leases.
#
# Usage:
#   lease-check.sh                  # list all leases
#   lease-check.sh <slug>           # report just that one
#   lease-check.sh --json           # JSON output, all leases
#   lease-check.sh <slug> --json    # JSON output, one lease
#
# Status taxonomy:
#   active   — heartbeat within STALE_THRESHOLD_MINUTES (default 30)
#   stale    — heartbeat older than STALE_THRESHOLD_MINUTES
#   corrupt  — file exists but JSON is malformed
#
# Human-readable output: one line per lease, tab-separated:
#   <slug>\t<status>\t<age-in-minutes>\t<intent>
#
# Exit codes:
#   0  — at least one lease found (no-arg) OR the named slug found
#   1  — no leases at all (no-arg) OR named slug not found
#   2  — invalid slug

set -euo pipefail

STALE_THRESHOLD_MINUTES="${STALE_THRESHOLD_MINUTES:-30}"

# Argument parsing — optional slug + optional --json flag in either order.
SLUG=""
JSON_OUTPUT=false
for arg in "$@"; do
  case "$arg" in
    --json) JSON_OUTPUT=true ;;
    *)
      if [ -z "$SLUG" ]; then
        SLUG="$arg"
      else
        echo "usage: $(basename "$0") [<slug>] [--json]" >&2
        exit 2
      fi
      ;;
  esac
done

if [ -n "$SLUG" ]; then
  if ! echo "$SLUG" | grep -qE '^[a-z0-9][a-z0-9-]*$'; then
    echo "invalid slug: $SLUG (must be kebab-case: lowercase + digits + hyphens)" >&2
    exit 2
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LEASES_DIR="${LEASES_DIR:-$REPO_ROOT/.claude/state/leases}"

NOW_EPOCH="$(date -u +%s)"

# Classify a single lease file. Outputs one record to stdout (one line for
# human, one JSON object for --json). Returns 0 if classified.
classify_lease() {
  local lease_file="$1"
  local slug_from_file
  slug_from_file="$(basename "$lease_file" .json)"

  if ! jq -e . "$lease_file" >/dev/null 2>&1; then
    if $JSON_OUTPUT; then
      jq -nc --arg slug "$slug_from_file" '{slug:$slug, status:"corrupt"}'
    else
      printf '%s\t%s\t%s\t%s\n' "$slug_from_file" "corrupt" "-" "-"
    fi
    return 0
  fi

  local heartbeat
  heartbeat="$(jq -r '.heartbeat_at' "$lease_file")"
  local intent
  intent="$(jq -r '.intent // ""' "$lease_file")"

  local heartbeat_epoch
  heartbeat_epoch="$(date -u -d "$heartbeat" +%s 2>/dev/null || echo 0)"
  local age_seconds=$(( NOW_EPOCH - heartbeat_epoch ))
  local age_minutes=$(( age_seconds / 60 ))

  local status
  if [ "$age_minutes" -gt "$STALE_THRESHOLD_MINUTES" ]; then
    status="stale"
  else
    status="active"
  fi

  if $JSON_OUTPUT; then
    jq -nc \
      --arg slug "$slug_from_file" \
      --arg status "$status" \
      --argjson age "$age_minutes" \
      --arg intent "$intent" \
      '{slug:$slug, status:$status, age_minutes:$age, intent:$intent}'
  else
    printf '%s\t%s\t%dm\t%s\n' "$slug_from_file" "$status" "$age_minutes" "$intent"
  fi
}

# Single-slug mode.
if [ -n "$SLUG" ]; then
  LEASE_FILE="$LEASES_DIR/$SLUG.json"
  if [ ! -f "$LEASE_FILE" ]; then
    if $JSON_OUTPUT; then
      jq -nc --arg slug "$SLUG" '{slug:$slug, status:"missing"}'
    else
      echo "no such lease: $SLUG" >&2
    fi
    exit 1
  fi
  classify_lease "$LEASE_FILE"
  exit 0
fi

# List-all mode.
if [ ! -d "$LEASES_DIR" ]; then
  exit 1
fi

FOUND=0
shopt -s nullglob
for f in "$LEASES_DIR"/*.json; do
  classify_lease "$f"
  FOUND=1
done

if [ "$FOUND" -eq 0 ]; then
  exit 1
fi
