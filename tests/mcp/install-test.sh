#!/usr/bin/env bash
# Tests for richardbot-init mcp install
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
BIN="$REPO_ROOT/bin/richardbot-init"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "  pass: $1"; }

# Set up a minimal target by running 'init' against an empty dir.
TARGET="$TEST_TMP/target"
mkdir -p "$TARGET"
( cd "$TARGET" && bash "$BIN" init "$TARGET" > /dev/null 2>&1 ) || fail "init failed"
[[ -d "$TARGET/.claude" ]] || fail "init didn't create .claude/"

# Prepare a --keys-from file with values for circleci's env var.
KEYS_FILE="$TEST_TMP/keys.env"
cat > "$KEYS_FILE" <<KEYS
CIRCLECI_TOKEN=CCIPAT_test_value_1234
SENTRY_AUTH_TOKEN=sntrys_test_value
SENTRY_ORG=test-org
KEYS

# 1. mcp install single name with --keys-from succeeds, .mcp.json created, env written, manifest written.
bash "$BIN" mcp install circleci --keys-from "$KEYS_FILE" --yes "$TARGET" > /dev/null 2>&1 || fail "mcp install circleci failed"
[[ -f "$TARGET/.mcp.json" ]] || fail "mcp install did not create .mcp.json"
jq -e '.mcpServers.circleci' "$TARGET/.mcp.json" > /dev/null || fail ".mcp.json missing mcpServers.circleci"
[[ -f "$TARGET/.claude/env" ]] || fail "mcp install did not create .claude/env"
grep -q 'CIRCLECI_TOKEN=' "$TARGET/.claude/env" || fail ".claude/env missing CIRCLECI_TOKEN export"
[[ -f "$TARGET/.claude/MCPS" ]] || fail "mcp install did not create .claude/MCPS manifest"
grep -qx 'circleci' "$TARGET/.claude/MCPS" || fail ".claude/MCPS missing circleci entry"
pass "single MCP install: .mcp.json + .claude/env + .claude/MCPS all populated"

# 2. _comment* fields stripped from the installed stanza.
if jq -e '.mcpServers.circleci | keys | map(select(startswith("_comment"))) | length > 0' "$TARGET/.mcp.json" > /dev/null; then
  fail "_comment* fields not stripped from installed stanza"
fi
pass "_comment fields stripped from stanza"

# 3. Multi-MCP install in one call.
bash "$BIN" mcp install sentry shopify --keys-from "$KEYS_FILE" --yes "$TARGET" > /dev/null 2>&1 || fail "mcp install sentry shopify failed"
jq -e '.mcpServers.sentry' "$TARGET/.mcp.json" > /dev/null || fail "sentry stanza missing after multi-install"
jq -e '.mcpServers.shopify' "$TARGET/.mcp.json" > /dev/null || fail "shopify stanza missing after multi-install"
grep -qx 'sentry' "$TARGET/.claude/MCPS" || fail "sentry not in MCPS manifest"
grep -qx 'shopify' "$TARGET/.claude/MCPS" || fail "shopify not in MCPS manifest"
pass "multi-MCP install adds both stanzas + manifest entries"

# 4. Existing stanzas preserved on subsequent install (idempotency-like).
bash "$BIN" mcp install jira --keys-from "$KEYS_FILE" --yes "$TARGET" > /dev/null 2>&1 || fail "mcp install jira failed"
jq -e '.mcpServers.circleci' "$TARGET/.mcp.json" > /dev/null || fail "circleci stanza lost on subsequent install"
jq -e '.mcpServers.sentry' "$TARGET/.mcp.json" > /dev/null || fail "sentry stanza lost on subsequent install"
jq -e '.mcpServers.jira' "$TARGET/.mcp.json" > /dev/null || fail "jira stanza not added"
pass "subsequent install preserves prior stanzas"

# 5. Unknown MCP name does not corrupt state.
bash "$BIN" mcp install bogus-mcp-name --yes "$TARGET" > /dev/null 2>&1 || true
jq -e '.mcpServers.circleci' "$TARGET/.mcp.json" > /dev/null || fail "state corrupted by unknown MCP install attempt"
if jq -e '.mcpServers["bogus-mcp-name"]' "$TARGET/.mcp.json" > /dev/null 2>&1; then
  fail "bogus MCP added to .mcp.json"
fi
pass "unknown MCP name does not corrupt state"

# 6. Pre-existing env var in .claude/env is preserved (not duplicated).
echo 'export CIRCLECI_TOKEN="preserved_value"' >> "$TARGET/.claude/env"
bash "$BIN" mcp install circleci --keys-from "$KEYS_FILE" --yes "$TARGET" > /dev/null 2>&1 || fail "re-install of circleci failed"
COUNT=$(grep -c 'CIRCLECI_TOKEN=' "$TARGET/.claude/env" || echo 0)
# Should NOT have added another CIRCLECI_TOKEN line — the install detected it was already there.
# We started with 1 (from first install) + 1 (the manual add we just did) = 2. After this re-install, still 2.
[[ "$COUNT" -le 2 ]] || fail "CIRCLECI_TOKEN duplicated on re-install (count=$COUNT)"
pass "pre-existing env var not duplicated on re-install"

# 7. mcp list reads the manifest.
LIST_OUT=$(bash "$BIN" mcp list "$TARGET")
echo "$LIST_OUT" | grep -q 'circleci' || fail "mcp list missing circleci"
echo "$LIST_OUT" | grep -q 'sentry' || fail "mcp list missing sentry"
pass "mcp list enumerates installed MCPs"

echo "install-test.sh PASS"
