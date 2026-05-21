#!/usr/bin/env bash
# Tests for lease-acquire.sh
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
ACQUIRE="$REPO_ROOT/.claude/hooks/lease-acquire.sh"
RELEASE="$REPO_ROOT/.claude/hooks/lease-release.sh"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
export LEASES_DIR="$TEST_TMP"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "  pass: $1"; }

# 1. Fresh slug succeeds + lease file created with correct shape.
"$ACQUIRE" acq-test-fresh "first acquire" > /dev/null
[[ -f "$TEST_TMP/acq-test-fresh.json" ]] || fail "lease file not created"
jq -e '.slug == "acq-test-fresh"' "$TEST_TMP/acq-test-fresh.json" > /dev/null || fail "slug field wrong"
jq -e '.intent == "first acquire"' "$TEST_TMP/acq-test-fresh.json" > /dev/null || fail "intent field wrong"
jq -e '.pid != null' "$TEST_TMP/acq-test-fresh.json" > /dev/null || fail "pid field missing"
jq -e '.host != null' "$TEST_TMP/acq-test-fresh.json" > /dev/null || fail "host field missing"
jq -e '.started_at != null' "$TEST_TMP/acq-test-fresh.json" > /dev/null || fail "started_at missing"
jq -e '.heartbeat_at != null' "$TEST_TMP/acq-test-fresh.json" > /dev/null || fail "heartbeat_at missing"
pass "fresh slug succeeds with correct JSON shape"

# 2. Held slug fails (exit 1).
if "$ACQUIRE" acq-test-fresh "second attempt" 2>/dev/null; then
  fail "second acquire on held slug should have failed"
fi
pass "held slug conflicts on re-acquire"

# 3. After release, slug can be re-acquired.
"$RELEASE" acq-test-fresh > /dev/null
"$ACQUIRE" acq-test-fresh "re-acquire after release" > /dev/null
[[ -f "$TEST_TMP/acq-test-fresh.json" ]] || fail "lease not re-created after release"
pass "re-acquire after release succeeds"

# 4. Invalid slug rejected.
if "$ACQUIRE" "Bad_Slug" "..." 2>/dev/null; then
  fail "invalid slug 'Bad_Slug' should have been rejected"
fi
if "$ACQUIRE" "has spaces" "..." 2>/dev/null; then
  fail "invalid slug 'has spaces' should have been rejected"
fi
if "$ACQUIRE" "has/slash" "..." 2>/dev/null; then
  fail "invalid slug 'has/slash' should have been rejected"
fi
pass "invalid slugs rejected (uppercase, spaces, slash)"

# 5. Missing args.
if "$ACQUIRE" acq-only-arg 2>/dev/null; then
  fail "missing intent should have errored"
fi
if "$ACQUIRE" 2>/dev/null; then
  fail "no args should have errored"
fi
pass "missing args rejected"

echo "acquire-test.sh PASS"
