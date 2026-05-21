#!/usr/bin/env bash
# Tests for lease-check.sh
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
ACQUIRE="$REPO_ROOT/.claude/hooks/lease-acquire.sh"
CHECK="$REPO_ROOT/.claude/hooks/lease-check.sh"
RELEASE="$REPO_ROOT/.claude/hooks/lease-release.sh"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
export LEASES_DIR="$TEST_TMP"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "  pass: $1"; }

# 1. Empty leases dir: list-all exits 1.
if "$CHECK" 2>/dev/null; then
  fail "list-all on empty dir should exit 1"
fi
pass "list-all on empty dir exits non-zero"

# 2. Missing slug: with-slug exits 1.
if "$CHECK" never-acquired 2>/dev/null; then
  fail "with-slug for missing lease should exit 1"
fi
pass "with-slug for missing exits non-zero"

# 3. Active lease: with-slug exits 0, classifies as active.
"$ACQUIRE" check-active "active test" > /dev/null
OUT="$("$CHECK" check-active)"
[[ "$OUT" == *"check-active"* ]] || fail "output missing slug"
[[ "$OUT" == *"active"* ]] || fail "fresh lease not classified active: $OUT"
pass "fresh lease classified active"

# 4. --json flag produces valid JSON.
JSON_OUT="$("$CHECK" check-active --json)"
echo "$JSON_OUT" | jq -e '.status == "active"' > /dev/null || fail "JSON output missing status:active"
echo "$JSON_OUT" | jq -e '.slug' > /dev/null || fail "JSON output missing slug"
pass "--json emits valid JSON with status field"

# 5. Stale lease: backdate heartbeat_at to >30 min ago, expect 'stale' status.
STALE_TIME="$(date -u -d '45 minutes ago' +%Y-%m-%dT%H:%M:%SZ)"
"$ACQUIRE" check-stale "stale test" > /dev/null
jq --arg t "$STALE_TIME" '.heartbeat_at = $t' "$TEST_TMP/check-stale.json" > "$TEST_TMP/check-stale.json.tmp"
mv "$TEST_TMP/check-stale.json.tmp" "$TEST_TMP/check-stale.json"
OUT="$("$CHECK" check-stale)"
[[ "$OUT" == *"stale"* ]] || fail "old-heartbeat lease not classified stale: $OUT"
pass "old-heartbeat lease classified stale"

# 6. Corrupt lease: write malformed JSON, expect 'corrupt' status.
echo "{ this is not json" > "$TEST_TMP/check-corrupt.json"
OUT="$("$CHECK" check-corrupt)"
[[ "$OUT" == *"corrupt"* ]] || fail "malformed JSON not classified corrupt: $OUT"
pass "malformed JSON classified corrupt"

# 7. List-all lists multiple leases.
LIST="$("$CHECK")"
LINES=$(echo "$LIST" | wc -l)
[[ "$LINES" -ge 3 ]] || fail "list-all should show >=3 leases (active+stale+corrupt), got $LINES"
pass "list-all enumerates multiple leases"

echo "check-test.sh PASS"
