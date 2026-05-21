#!/usr/bin/env bash
# lease-acquire.sh - acquire a named lease (cross-process work-in-flight marker).
#
# Usage:
#   lease-acquire.sh <slug> <intent>
#
# Atomically creates .claude/state/leases/<slug>.json if no lease with that
# slug is currently held. Exits 1 if the slug is already taken. Slug must
# be kebab-case (lowercase letters, digits, hyphens only).
#
# State dir is configurable via LEASES_DIR env var (default: repo
# .claude/state/leases relative to this script).
#
# On success: prints the lease file path to stdout; exit 0.
# On conflict: prints "lease held: <slug>" to stderr; exit 1.
# On invalid slug: prints "invalid slug: <slug>" to stderr; exit 2.
# On missing args: prints usage to stderr; exit 2.

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "usage: $(basename "$0") <slug> <intent>" >&2
  exit 2
fi

SLUG="$1"
INTENT="$2"

# Slug validation: lowercase letters, digits, hyphens only.
if ! echo "$SLUG" | grep -qE '^[a-z0-9][a-z0-9-]*$'; then
  echo "invalid slug: $SLUG (must be kebab-case: lowercase + digits + hyphens)" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LEASES_DIR="${LEASES_DIR:-$REPO_ROOT/.claude/state/leases}"
mkdir -p "$LEASES_DIR"

LEASE_FILE="$LEASES_DIR/$SLUG.json"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
HOST="$(hostname)"
PID=$$

LEASE_JSON=$(jq -nc \
  --arg slug "$SLUG" \
  --arg intent "$INTENT" \
  --arg started "$NOW" \
  --arg heartbeat "$NOW" \
  --arg host "$HOST" \
  --argjson pid "$PID" \
  '{slug:$slug, intent:$intent, pid:$pid, host:$host, started_at:$started, heartbeat_at:$heartbeat}')

# Atomic create-if-not-exist via noclobber.
set -o noclobber
if ! echo "$LEASE_JSON" > "$LEASE_FILE" 2>/dev/null; then
  echo "lease held: $SLUG" >&2
  exit 1
fi
set +o noclobber

echo "$LEASE_FILE"
