#!/bin/bash
# Smoke Tests: Laeuft der Container grundsaetzlich korrekt?

IMAGE="${IMAGE:-ghcr.io/google/gemini-cli:latest}"
PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  local expect="$3"
  if echo "$result" | grep -q "$expect"; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc"
    echo "      Erwartet: '$expect'"
    echo "      Erhalten: '$result'"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Smoke Tests: $IMAGE ==="
echo ""

# Test 1: Container startet ueberhaupt
result=$(docker run --rm "$IMAGE" echo "ok" 2>&1)
check "Container startet" "$result" "ok"

# Test 2: Nicht als root
result=$(docker run --rm "$IMAGE" whoami 2>&1)
if echo "$result" | grep -q "^root$"; then
  echo "WARN: laeuft als root — sollte gehaertet werden"
  FAIL=$((FAIL + 1))
else
  echo "PASS: laeuft nicht als root (User: $result)"
  PASS=$((PASS + 1))
fi

# Test 3: OS-Release lesbar (Basis-Image identifizieren)
result=$(docker run --rm "$IMAGE" cat /etc/os-release 2>&1)
check "OS-Release lesbar" "$result" "ID="
echo "      Basis-Image: $(echo "$result" | grep '^ID=' | cut -d= -f2)"

# Test 4: Node.js vorhanden und Version bekannt
result=$(docker run --rm "$IMAGE" node --version 2>&1)
check "Node.js vorhanden" "$result" "v"

# Test 5: Gemini CLI binary vorhanden
result=$(docker run --rm "$IMAGE" which gemini 2>&1)
check "Gemini CLI binary gefunden" "$result" "gemini"

echo ""
echo "=== Ergebnis: $PASS PASS, $FAIL FAIL ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
