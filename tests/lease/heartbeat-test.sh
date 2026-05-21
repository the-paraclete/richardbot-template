#!/usr/bin/env bash
# Tests for lease-heartbeat.sh
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
ACQUIRE="$REPO_ROOT/.claude/hooks/lease-acquire.sh"
HEARTBEAT="$REPO_ROOT/.claude/hooks/lease-heartbeat.sh"
RELEASE="$REPO_ROOT/.claude/hooks/lease-release.sh"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
export LEASES_DIR="$TEST_TMP"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "  pass: $1"; }

# 1. Heartbeat updates heartbeat_at; started_at unchanged.
"$ACQUIRE" hb-test "to heartbeat" > /dev/null
ORIG_HB="$(jq -r .heartbeat_at "$TEST_TMP/hb-test.json")"
ORIG_START="$(jq -r .started_at "$TEST_TMP/hb-test.json")"
sleep 1.1
"$HEARTBEAT" hb-test > /dev/null
NEW_HB="$(jq -r .heartbeat_at "$TEST_TMP/hb-test.json")"
NEW_START="$(jq -r .started_at "$TEST_TMP/hb-test.json")"
[[ "$NEW_HB" != "$ORIG_HB" ]] || fail "heartbeat_at did not change (orig=$ORIG_HB new=$NEW_HB)"
[[ "$NEW_START" == "$ORIG_START" ]] || fail "started_at changed but shouldn't (orig=$ORIG_START new=$NEW_START)"
pass "heartbeat updates heartbeat_at without touching started_at"

# 2. Lease file remains valid JSON after heartbeat (no partial-write corruption).
jq -e . "$TEST_TMP/hb-test.json" > /dev/null || fail "lease file not valid JSON after heartbeat"
pass "lease file remains valid JSON after heartbeat"

# 3. Heartbeat on missing lease fails (exit 1).
if "$HEARTBEAT" hb-test-never-acquired 2>/dev/null; then
  fail "heartbeat on missing lease should have failed"
fi
pass "heartbeat on missing lease fails"

# 4. Invalid slug rejected.
if "$HEARTBEAT" "Bad_Slug" 2>/dev/null; then
  fail "invalid slug should have been rejected"
fi
pass "invalid slug rejected"

# 5. Other lease fields preserved.
"$RELEASE" hb-test > /dev/null
"$ACQUIRE" hb-test "preserve check" > /dev/null
ORIG_PID="$(jq -r .pid "$TEST_TMP/hb-test.json")"
ORIG_HOST="$(jq -r .host "$TEST_TMP/hb-test.json")"
ORIG_INTENT="$(jq -r .intent "$TEST_TMP/hb-test.json")"
"$HEARTBEAT" hb-test > /dev/null
[[ "$(jq -r .pid "$TEST_TMP/hb-test.json")" == "$ORIG_PID" ]] || fail "pid changed"
[[ "$(jq -r .host "$TEST_TMP/hb-test.json")" == "$ORIG_HOST" ]] || fail "host changed"
[[ "$(jq -r .intent "$TEST_TMP/hb-test.json")" == "$ORIG_INTENT" ]] || fail "intent changed"
pass "pid/host/intent preserved across heartbeat"

echo "heartbeat-test.sh PASS"
