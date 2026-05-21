#!/usr/bin/env bash
# lease-heartbeat.sh - update a lease's heartbeat_at timestamp.
#
# Usage:
#   lease-heartbeat.sh <slug>
#
# Atomically updates heartbeat_at in the lease file via temp + mv on the
# same filesystem. Slug must be kebab-case (same validation as acquire).
#
# On success: prints "heartbeat <slug> <iso-time>" to stdout; exit 0.
# On missing lease: prints "no such lease: <slug>" to stderr; exit 1.
# On invalid slug: prints "invalid slug"; exit 2.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: $(basename "$0") <slug>" >&2
  exit 2
fi

SLUG="$1"

if ! echo "$SLUG" | grep -qE '^[a-z0-9][a-z0-9-]*$'; then
  echo "invalid slug: $SLUG (must be kebab-case: lowercase + digits + hyphens)" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LEASES_DIR="${LEASES_DIR:-$REPO_ROOT/.claude/state/leases}"

LEASE_FILE="$LEASES_DIR/$SLUG.json"

if [ ! -f "$LEASE_FILE" ]; then
  echo "no such lease: $SLUG" >&2
  exit 1
fi

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TMP_FILE="$(mktemp "${LEASE_FILE}.XXXXXX")"

# jq reads the old file and writes to tmp with updated heartbeat_at.
if ! jq --arg heartbeat "$NOW" '.heartbeat_at = $heartbeat' "$LEASE_FILE" > "$TMP_FILE"; then
  rm -f "$TMP_FILE"
  echo "failed to read/parse lease: $SLUG" >&2
  exit 1
fi

# Atomic rename on the same filesystem (POSIX guarantee).
mv "$TMP_FILE" "$LEASE_FILE"

echo "heartbeat $SLUG $NOW"
