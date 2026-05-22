#!/usr/bin/env bash
# Tests for richardbot-init mcp remove
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
BIN="$REPO_ROOT/bin/richardbot-init"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "  pass: $1"; }

TARGET="$TEST_TMP/target"
mkdir -p "$TARGET"
( cd "$TARGET" && bash "$BIN" init "$TARGET" > /dev/null 2>&1 ) || fail "init failed"

KEYS_FILE="$TEST_TMP/keys.env"
cat > "$KEYS_FILE" <<KEYS
CIRCLECI_TOKEN=test1
SENTRY_AUTH_TOKEN=test2
SENTRY_ORG=test-org
KEYS

# Install three MCPs first so we have something to remove.
bash "$BIN" mcp install circleci sentry shopify --keys-from "$KEYS_FILE" --yes "$TARGET" > /dev/null 2>&1 || fail "setup install failed"

# 1. Remove one — stanza gone, others preserved.
bash "$BIN" mcp remove sentry "$TARGET" > /dev/null 2>&1 || fail "remove sentry failed"
if jq -e '.mcpServers.sentry' "$TARGET/.mcp.json" > /dev/null 2>&1; then
  fail "sentry stanza still in .mcp.json after remove"
fi
jq -e '.mcpServers.circleci' "$TARGET/.mcp.json" > /dev/null || fail "circleci stanza lost on sentry remove"
jq -e '.mcpServers.shopify' "$TARGET/.mcp.json" > /dev/null || fail "shopify stanza lost on sentry remove"
pass "remove one strips stanza; others preserved"

# 2. Manifest updated.
if grep -qx 'sentry' "$TARGET/.claude/MCPS"; then
  fail "sentry still in MCPS manifest after remove"
fi
grep -qx 'circleci' "$TARGET/.claude/MCPS" || fail "circleci dropped from manifest on sentry remove"
pass "manifest updated correctly on remove"

# 3. Env vars preserved (operator owns them; cleanup is manual).
grep -q 'SENTRY_AUTH_TOKEN=' "$TARGET/.claude/env" || fail "SENTRY_AUTH_TOKEN dropped from .claude/env on remove"
pass "env vars preserved on remove (operator must clean manually)"

# 4. Remove of non-installed MCP is graceful (no state corruption).
bash "$BIN" mcp remove never-installed-mcp "$TARGET" > /dev/null 2>&1 || true
jq -e '.mcpServers.circleci' "$TARGET/.mcp.json" > /dev/null || fail "state corrupted by remove of unknown"
pass "remove of unknown MCP is graceful"

# 5. Multi-remove.
bash "$BIN" mcp remove circleci shopify "$TARGET" > /dev/null 2>&1 || fail "multi-remove failed"
SERVER_COUNT=$(jq '.mcpServers | length' "$TARGET/.mcp.json")
[[ "$SERVER_COUNT" -eq 0 ]] || fail "expected mcpServers to be empty after removing all, got $SERVER_COUNT"
[[ ! -f "$TARGET/.claude/MCPS" ]] || fail "MCPS manifest should be removed when empty"
pass "multi-remove + empty manifest cleaned up"

echo "remove-test.sh PASS"
