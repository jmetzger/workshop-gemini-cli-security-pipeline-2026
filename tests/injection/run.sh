#!/bin/bash
# Prompt Injection Tests
#
# Wichtig: Diese Tests pruefen ob der Agent auf Injektionsversuche reagiert.
# Ein "PASS" bedeutet: der Agent hat den Befehl NICHT ausgefuehrt.
# Ein "FAIL" bedeutet: der Agent hat etwas getan was er nicht sollte.
#
# Grenze: Wir koennen nicht alle moeglichen Injektionen testen.
# Diese Tests sind Stichproben — kein vollstaendiger Sicherheitsnachweis.

IMAGE="${IMAGE:-ghcr.io/google/gemini-cli:latest}"
SETTINGS="${SETTINGS:-$(pwd)/settings.json}"
PASS=0
FAIL=0
WARN=0

pass() { echo "PASS [$1]: $2"; PASS=$((PASS + 1)); }
fail() { echo "FAIL [$1]: $2"; echo "      $3"; FAIL=$((FAIL + 1)); }
warn() { echo "WARN [$1]: $2"; WARN=$((WARN + 1)); }

echo "=== Prompt Injection Tests: $IMAGE ==="
echo "    Hinweis: PASS = Injektion wurde NICHT ausgefuehrt"
echo ""

while IFS='|' read -r case_id input must_not description; do
  [[ "$case_id" =~ ^#.*$ || -z "$case_id" ]] && continue

  # Agent mit adversarialem Input ausfuehren
  # Netzwerk geblockt — direkte Exfiltration schon durch Sandbox verhindert
  actual=$(echo "$input" | docker run --rm -i \
    --network none \
    --read-only \
    --tmpfs /tmp:size=50m,mode=1777 \
    -v "$SETTINGS":/root/.gemini/settings.json:ro \
    "$IMAGE" \
    sh -c "gemini 2>&1" || true)

  # Pruefen ob verbotenes Muster im Output erscheint
  if echo "$actual" | grep -qi "$must_not"; then
    fail "$case_id" "$description" "Verbotenes Muster '$must_not' im Output gefunden"
    echo "      Output: $(echo "$actual" | head -3)"
  else
    pass "$case_id" "$description"
  fi

done < "$(dirname "$0")/cases.txt"

echo ""
echo "=== Ergebnis: $PASS PASS, $FAIL FAIL, $WARN WARN ==="
echo ""
echo "Erinnerung: PASS hier bedeutet das der Agent nicht"
echo "auf den Injektionsversuch reagiert hat — nicht dass"
echo "das System vollstaendig gegen Injektionen geschuetzt ist."
echo ""
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
