#!/bin/bash
# Behavioral Tests: Tut der Agent was erwartet wird?
#
# Wichtig: Kein Exact-String-Matching — LLM-Output ist nicht deterministisch.
# Wir testen Verhalten (was der Agent tut) und Pattern (was er schreibt).

IMAGE="${IMAGE:-ghcr.io/google/gemini-cli:latest}"
SETTINGS="${SETTINGS:-$(pwd)/settings.json}"
WORKSPACE="${WORKSPACE:-$(pwd)/tests/behavioral/workspace}"
PASS=0
FAIL=0
WARN=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; echo "      $2"; FAIL=$((FAIL + 1)); }
warn() { echo "WARN: $1"; echo "      $2"; WARN=$((WARN + 1)); }

echo "=== Behavioral Tests: $IMAGE ==="
echo ""

# Workspace mit Testdateien vorbereiten
mkdir -p "$WORKSPACE"
echo "Testdatei A" > "$WORKSPACE/file_a.txt"
echo "Testdatei B" > "$WORKSPACE/file_b.txt"

# Agent ausfuehren (ohne Netzwerk, read-only ausserhalb workspace)
actual=$(docker run --rm \
  --network none \
  --read-only \
  --tmpfs /tmp:size=50m,mode=1777 \
  -v "$SETTINGS":/root/.gemini/settings.json:ro \
  -v "$WORKSPACE":/workspace:ro \
  "$IMAGE" \
  sh -c "gemini < /workspace/../input.txt 2>&1" || true)

echo "Agent Output:"
echo "---"
echo "$actual"
echo "---"
echo ""

# Pattern-Checks aus expected_patterns.txt ausfuehren
while IFS='|' read -r check_type pattern description; do
  # Kommentare und leere Zeilen ueberspringen
  [[ "$check_type" =~ ^#.*$ || -z "$check_type" ]] && continue

  case "$check_type" in
    MUST_CONTAIN)
      if echo "$actual" | grep -qi "$pattern"; then
        pass "$description"
      else
        fail "$description" "Pattern '$pattern' nicht gefunden"
      fi
      ;;
    MUST_NOT)
      if echo "$actual" | grep -qi "$pattern"; then
        fail "$description" "Unerwuenschtes Pattern '$pattern' gefunden"
      else
        pass "$description"
      fi
      ;;
    WARN_IF)
      if echo "$actual" | grep -qi "$pattern"; then
        warn "$description" "Pattern '$pattern' gefunden — pruefen"
      fi
      ;;
  esac
done < "$(dirname "$0")/expected_patterns.txt"

echo ""
echo "=== Ergebnis: $PASS PASS, $FAIL FAIL, $WARN WARN ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
