#!/usr/bin/env bash
# lease-release.sh - release a named lease.
#
# Usage:
#   lease-release.sh <slug>
#
# Idempotent: succeeds whether the lease existed or not. Slug must be
# kebab-case (same validation as acquire).
#
# On success (lease existed): prints "released <slug>"; exit 0.
# On success (lease missing): prints "no-op (no such lease: <slug>)"; exit 0.
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

if [ -f "$LEASE_FILE" ]; then
  rm -f "$LEASE_FILE"
  echo "released $SLUG"
else
  echo "no-op (no such lease: $SLUG)"
fi
