#!/usr/bin/env bash
# Tests for the Copilot discipline layer: the static preamble, the
# sentinel-managed generated region, and the clobber-regression guard.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/../.." && pwd)"
BIN="$REPO_ROOT/bin/richardbot-init"

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "  pass: $1"; }

SENTINEL='<!-- BEGIN richardbot-mirror — generated; everything below is overwritten on re-run -->'

# ── a. bare `init` emits .github/copilot-instructions.md (item 3) ───────────
TARGET="$TEST_TMP/target"
mkdir -p "$TARGET"
( cd "$TARGET" && bash "$BIN" init "$TARGET" > /dev/null 2>&1 ) || fail "init failed"
MAIN="$TARGET/.github/copilot-instructions.md"
[[ -f "$MAIN" ]] || fail "bare init did not create .github/copilot-instructions.md"
pass "a. bare init scaffolds .github/copilot-instructions.md"

# ── b. honesty discipline + memory protocol strings present ─────────────────
grep -q "Never claim an action you did not take" "$MAIN" \
  || fail "honesty discipline string missing"
grep -q "A plan is not a deliverable" "$MAIN" \
  || fail "completion discipline string missing"
grep -q "_recent.md" "$MAIN" || fail "memory protocol _recent.md reference missing"
grep -q "you have no memory" "$MAIN" || fail "memory protocol 'you have no memory' missing"
pass "b. honesty + memory protocol strings present"

# ── b'. shipped preamble uses .richardbot-memory/ (not the standalone path) ──
grep -q '\.richardbot-memory/' "$MAIN" \
  || fail "template-shipped preamble should reference .richardbot-memory/"
grep -q '\.ai-memory/' "$MAIN" \
  && fail "template-shipped preamble must NOT reference .ai-memory/ (that's the standalone)"
pass "b'. shipped preamble uses .richardbot-memory/ path"

# ── c. the BEGIN sentinel is present ────────────────────────────────────────
grep -qF "$SENTINEL" "$MAIN" || fail "sentinel marker missing from copilot-instructions.md"
pass "c. BEGIN sentinel present"

# ── d. preservation / clobber-regression: a hand-edit above the sentinel ────
#       survives a copilot-mirror re-run, AND the generated region refreshes ──
MARKER="HAND-EDITED-MARKER-$$-do-not-clobber"
# Insert the marker into the preserved (preamble) region, above the sentinel.
python3 - "$MAIN" "$MARKER" "$SENTINEL" <<'PYEOF'
import sys
path, marker, sentinel = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path).read()
idx = text.index(sentinel)
# Splice the marker line in just above the sentinel (still in preamble region).
new = text[:idx] + marker + "\n\n" + text[idx:]
open(path, "w").write(new)
PYEOF
grep -qF "$MARKER" "$MAIN" || fail "test setup: marker not written above sentinel"

# Add a fresh rule whose body must appear in the regenerated region after mirror.
GEN_PROOF="GENERATED-REGION-PROOF-$$"
cat > "$TARGET/.claude/rules/zz-mirror-proof.md" <<RULE
---
description: regen proof rule
alwaysApply: true
---

# Mirror proof

$GEN_PROOF
RULE

bash "$BIN" copilot-mirror "$TARGET" > /dev/null 2>&1 || fail "copilot-mirror re-run failed"

# d.1 — the hand-edit above the sentinel SURVIVED (the clobber regression guard)
grep -qF "$MARKER" "$MAIN" || fail "clobber regression: hand-edit above sentinel was WIPED by re-run"
# d.2 — and it is still above the sentinel, not relocated below it
PRE="$(awk -v s="$SENTINEL" 'index($0,s){exit} {print}' "$MAIN")"
echo "$PRE" | grep -qF "$MARKER" || fail "marker survived but is no longer above the sentinel"
# d.3 — the generated region actually refreshed (new rule body landed below)
POST="$(awk -v s="$SENTINEL" 'f{print} index($0,s){f=1}' "$MAIN")"
echo "$POST" | grep -qF "$GEN_PROOF" || fail "generated region did not refresh below the sentinel"
pass "d. hand-edit above sentinel survives re-run; generated region refreshes"

# ── e. an alwaysApply:true rule body appears BELOW the sentinel ─────────────
#       conventions.md ships alwaysApply: true — its body must fold in below.
echo "$POST" | grep -q "Smallest reversible" \
  || fail "alwaysApply rule body not folded below sentinel"
pass "e. alwaysApply rule body folds below the sentinel"

# ── f. _recent.md digest format in README matches the preamble §2b format ────
#       Both describe: 'YYYY-MM-DD <type> <filename> — <one-line ...>'
README="$TARGET/.richardbot-memory/README.md"
grep -q 'YYYY-MM-DD' "$README" || fail ".richardbot-memory/README.md lost YYYY-MM-DD digest format"
grep -q 'YYYY-MM-DD' "$MAIN" || fail "preamble lost the YYYY-MM-DD digest format reference"
# The README must carry the 'Copilot consumers' note (item 4).
grep -qi 'Copilot' "$README" || fail ".richardbot-memory/README.md missing Copilot consumers note"
pass "f. README digest format matches preamble; Copilot consumers note present"

echo "mirror-test.sh PASS"
