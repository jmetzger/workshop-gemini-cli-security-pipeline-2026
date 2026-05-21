#!/bin/bash
# Guardrail Tests: Halten die technischen Grenzen?
# Testet Ebene 1 (Sandbox) — nicht LLM-Verhalten

IMAGE="${IMAGE:-ghcr.io/google/gemini-cli:latest}"
PASS=0
FAIL=0
WARN=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; echo "      $2"; FAIL=$((FAIL + 1)); }
warn() { echo "WARN: $1"; echo "      $2"; WARN=$((WARN + 1)); }

echo "=== Guardrail Tests (Ebene 1 — Sandbox): $IMAGE ==="
echo ""

# --- Netzwerk ---
echo "-- Netzwerk-Guardrails --"

# Negativ-Test: kein Netzwerk wenn --network none
result=$(docker run --rm --network none "$IMAGE" \
  sh -c "curl -s --max-time 3 https://example.com 2>&1" || true)
if echo "$result" | grep -qi "could not resolve\|network unreachable\|connection refused\|name or service not known"; then
  pass "Netzwerk geblockt mit --network none"
else
  fail "Netzwerk NICHT geblockt mit --network none" "$result"
fi

# Negativ-Test: kein DNS-Lookup
result=$(docker run --rm --network none "$IMAGE" \
  sh -c "nslookup google.com 2>&1" || true)
if echo "$result" | grep -qi "can't resolve\|connection refused\|network unreachable\|nslookup: not found"; then
  pass "DNS geblockt mit --network none"
else
  warn "DNS-Test nicht eindeutig" "$result"
fi

echo ""
echo "-- Dateisystem-Guardrails --"

# Negativ-Test: kein Schreiben mit --read-only
result=$(docker run --rm --read-only "$IMAGE" \
  sh -c "touch /test_write 2>&1" || true)
if echo "$result" | grep -qi "read-only\|permission denied\|cannot touch"; then
  pass "Filesystem read-only mit --read-only"
else
  fail "Filesystem NICHT read-only mit --read-only" "$result"
fi

# Negativ-Test: kein Schreiben in /etc
result=$(docker run --rm --read-only "$IMAGE" \
  sh -c "echo test >> /etc/hosts 2>&1" || true)
if echo "$result" | grep -qi "read-only\|permission denied"; then
  pass "/etc nicht beschreibbar"
else
  fail "/etc beschreibbar — Konfiguration manipulierbar" "$result"
fi

# Positiv-Test: tmpfs funktioniert (noetig fuer Gemini CLI temp files)
result=$(docker run --rm --read-only \
  --tmpfs /tmp:size=50m,mode=1777 "$IMAGE" \
  sh -c "touch /tmp/test_ok && echo ok" 2>&1)
if echo "$result" | grep -q "ok"; then
  pass "/tmp beschreibbar via tmpfs (Gemini CLI braucht das)"
else
  fail "/tmp nicht beschreibbar — Gemini CLI wird nicht funktionieren" "$result"
fi

echo ""
echo "-- Privilege-Guardrails --"

# Negativ-Test: keine Privilege Escalation
result=$(docker run --rm --security-opt no-new-privileges "$IMAGE" \
  sh -c "sudo id 2>&1" || true)
if echo "$result" | grep -qi "sudo: not found\|command not found\|permission denied"; then
  pass "sudo nicht verfuegbar"
else
  warn "sudo vorhanden — pruefen ob noetig" "$result"
fi

# Negativ-Test: keine gefaehrlichen Capabilities
result=$(docker run --rm --cap-drop ALL "$IMAGE" \
  sh -c "echo ok" 2>&1)
if echo "$result" | grep -q "ok"; then
  pass "Container laeuft ohne Capabilities (--cap-drop ALL)"
else
  fail "Container benoetigt Capabilities die gedroppt wurden" "$result"
fi

echo ""
echo "-- Zusammenfassung --"
echo "PASS: $PASS | FAIL: $FAIL | WARN: $WARN"
echo ""
if [ "$FAIL" -gt 0 ]; then
  echo "Mindestens ein Guardrail haelt nicht — Pipeline-Fehler"
  exit 1
fi
[ "$WARN" -gt 0 ] && echo "Warnungen vorhanden — Review empfohlen"
exit 0
