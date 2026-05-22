#!/usr/bin/env bash
# run-tests.sh - run all tests in tests/*/. Exit non-zero on any failure.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
FAILED=0
PASSED=0

for suite_dir in "$TESTS_DIR"/*/; do
  [ -d "$suite_dir" ] || continue
  SUITE_NAME="$(basename "$suite_dir")"
  echo "=== suite: $SUITE_NAME ==="
  for test in "$suite_dir"*-test.sh; do
    [ -f "$test" ] || continue
    TEST_NAME="$(basename "$test")"
    echo "--- $TEST_NAME ---"
    if bash "$test"; then
      PASSED=$((PASSED + 1))
    else
      FAILED=$((FAILED + 1))
    fi
  done
  echo
done

echo "Suites: $PASSED passed, $FAILED failed"
exit $FAILED
