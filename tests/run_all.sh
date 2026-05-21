#!/bin/bash
# Alle Tests ausfuehren

IMAGE="${IMAGE:-ghcr.io/google/gemini-cli:latest}"
export IMAGE

TOTAL_FAIL=0

run_suite() {
  local name="$1"
  local script="$2"
  echo ""
  echo "############################################"
  echo "# Test Suite: $name"
  echo "############################################"
  bash "$script"
  local rc=$?
  [ "$rc" -ne 0 ] && TOTAL_FAIL=$((TOTAL_FAIL + 1))
  return $rc
}

run_suite "Smoke"       "tests/smoke/run.sh"
run_suite "Guardrails"  "tests/guardrails/run.sh"
run_suite "Behavioral"  "tests/behavioral/run.sh"
run_suite "Injection"   "tests/injection/run.sh"

echo ""
echo "############################################"
if [ "$TOTAL_FAIL" -eq 0 ]; then
  echo "# Alle Test Suites: PASS"
else
  echo "# $TOTAL_FAIL Test Suite(s) fehlgeschlagen"
fi
echo "############################################"
[ "$TOTAL_FAIL" -eq 0 ] && exit 0 || exit 1
