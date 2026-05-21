#!/usr/bin/env bash
# Tests for lease-release.sh
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

# 1. Release on held lease succeeds + file removed.
"$ACQUIRE" rel-test-held "to be released" > /dev/null
[[ -f "$TEST_TMP/rel-test-held.json" ]] || fail "setup: lease not created"
OUT="$("$RELEASE" rel-test-held)"
[[ "$OUT" == "released rel-test-held" ]] || fail "release output wrong: $OUT"
[[ ! -f "$TEST_TMP/rel-test-held.json" ]] || fail "lease file not removed"
pass "release on held succeeds and removes file"

# 2. Release on missing is idempotent (exit 0, no-op message).
OUT="$("$RELEASE" rel-test-never-held)"
[[ "$OUT" == "no-op (no such lease: rel-test-never-held)" ]] || fail "missing-release output wrong: $OUT"
pass "release on missing is idempotent"

# 3. Release after release is idempotent.
"$RELEASE" rel-test-held > /dev/null
pass "release after release is idempotent"

# 4. Invalid slug rejected (exit 2).
if "$RELEASE" "Bad_Slug" 2>/dev/null; then
  fail "invalid slug should have been rejected"
fi
pass "invalid slug rejected"

# 5. Missing args.
if "$RELEASE" 2>/dev/null; then
  fail "missing slug should have errored"
fi
pass "missing slug rejected"

echo "release-test.sh PASS"
