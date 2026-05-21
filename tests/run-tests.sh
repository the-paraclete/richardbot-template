#!/usr/bin/env bash
# run-tests.sh - run all tests in tests/. Exit non-zero on any failure.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
FAILED=0
PASSED=0

echo "Running lease tests..."
for test in "$TESTS_DIR"/lease/*-test.sh; do
  TEST_NAME="$(basename "$test")"
  echo "--- $TEST_NAME ---"
  if bash "$test"; then
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
  fi
done

echo
echo "Suites: $PASSED passed, $FAILED failed"
exit $FAILED
