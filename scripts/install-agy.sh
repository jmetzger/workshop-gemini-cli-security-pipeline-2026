#!/usr/bin/env bash
# Installationsscript fuer Antigravity CLI (agy) — Google's Go-basierter AI Terminal-Assistent
# Auth: Google OAuth (kein API-Key noetig — agy nutzt Google Sign-In)
# Ausfuehren: bash scripts/install-agy.sh
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
warn() { echo -e "${YELLOW}[!]${NC}   $*"; }
fail() { echo -e "${RED}[FEHLER]${NC} $*"; exit 1; }
info() { echo -e "${BLUE}[>>]${NC}  $*"; }

echo "========================================"
echo "  Antigravity CLI (agy) — Installation"
echo "========================================"
echo ""

# ── 1. Betriebssystem pruefen ────────────────────────────────────────────────
info "System pruefen ..."
OS=$(uname -s)
ARCH=$(uname -m)
if [[ "$OS" != "Linux" && "$OS" != "Darwin" ]]; then
  fail "Nicht unterstuetztes Betriebssystem: $OS (nur Linux/macOS)"
fi
ok "System: $OS / $ARCH"

# ── 2. curl pruefen ──────────────────────────────────────────────────────────
if ! command -v curl &>/dev/null; then
  info "curl nicht gefunden — installiere ..."
  sudo apt-get update -qq && sudo apt-get install -y curl || fail "curl konnte nicht installiert werden"
fi
ok "curl $(curl --version | head -1 | cut -d' ' -f2)"

# ── 3. Antigravity CLI installieren ──────────────────────────────────────────
echo ""
info "Antigravity CLI installieren ..."

if command -v agy &>/dev/null; then
  CURRENT_VER=$(agy --version 2>/dev/null || echo "unbekannt")
  warn "agy bereits installiert (Version: $CURRENT_VER) — aktualisiere ..."
fi

curl -fsSL https://antigravity.google/cli/install.sh | bash

# PATH fuer diese Session aktualisieren
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# Pruefe ob agy jetzt verfuegbar ist
if ! command -v agy &>/dev/null; then
  for dir in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
    if [[ -f "$dir/agy" ]]; then
      export PATH="$dir:$PATH"
      break
    fi
  done
fi

command -v agy &>/dev/null || fail "agy nach Installation nicht gefunden. Bitte PATH pruefen."
ok "Antigravity CLI installiert: $(agy --version 2>/dev/null || echo 'Version nicht auslesbar')"

# ── 4. SSH known_hosts fuer neuralpower aktualisieren ────────────────────────
echo ""
info "SSH-Verbindung zu neuralpower vorbereiten ..."

KNOWN_HOSTS="$HOME/.ssh/known_hosts"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if ssh-keyscan -T 5 neuralpower >> "$KNOWN_HOSTS" 2>/dev/null; then
  # Duplikate entfernen
  sort -u "$KNOWN_HOSTS" -o "$KNOWN_HOSTS" 2>/dev/null || true
  ok "SSH known_hosts fuer neuralpower aktualisiert"
else
  warn "ssh-keyscan fuer neuralpower fehlgeschlagen — Host evtl. nicht erreichbar"
fi

# ── 5. GEMINI_API_KEY von neuralpower holen (fuer Gemini CLI Kompatibilitaet) ─
# Hinweis: agy selbst nutzt Google OAuth, nicht GEMINI_API_KEY.
# Der Key wird fuer gemini CLI eingerichtet, falls benoetigt.
echo ""
info "GEMINI_API_KEY von neuralpower holen ..."

REMOTE_HOST="jmetzger@neuralpower"
REMOTE_KEY_FILE="/etc/profile.d/gemini-api.sh"
LOCAL_KEY_FILE="/etc/profile.d/gemini-api.sh"
TEMP_KEY_FILE=$(mktemp)
trap 'rm -f "$TEMP_KEY_FILE"' EXIT

# Zuerst ohne Passwort (SSH-Key) versuchen
if ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no \
       "$REMOTE_HOST" "test -f $REMOTE_KEY_FILE" 2>/dev/null; then

  scp -q -o StrictHostKeyChecking=no \
      "$REMOTE_HOST:$REMOTE_KEY_FILE" "$TEMP_KEY_FILE" \
      || fail "SCP von $REMOTE_HOST fehlgeschlagen"

  if ! grep -q "GEMINI_API_KEY" "$TEMP_KEY_FILE"; then
    fail "Unerwarteter Inhalt in $REMOTE_KEY_FILE — kein GEMINI_API_KEY gefunden"
  fi

  sudo cp "$TEMP_KEY_FILE" "$LOCAL_KEY_FILE"
  sudo chmod 644 "$LOCAL_KEY_FILE"
  sudo chown root:root "$LOCAL_KEY_FILE"
  # shellcheck source=/dev/null
  source "$LOCAL_KEY_FILE"
  ok "GEMINI_API_KEY eingerichtet: $LOCAL_KEY_FILE"

else
  # SSH-Key nicht hinterlegt — interaktiv mit Passwort versuchen
  warn "Kein SSH-Key fuer neuralpower — Passwort-Login wird versucht."
  echo "  Bitte SSH-Passwort fuer $REMOTE_HOST eingeben (oder Enter druecken zum Ueberspringen):"

  if scp -o StrictHostKeyChecking=no -o ConnectTimeout=15 \
         "$REMOTE_HOST:$REMOTE_KEY_FILE" "$TEMP_KEY_FILE" 2>/dev/null; then

    if ! grep -q "GEMINI_API_KEY" "$TEMP_KEY_FILE"; then
      fail "Unerwarteter Inhalt in $REMOTE_KEY_FILE — kein GEMINI_API_KEY gefunden"
    fi

    sudo cp "$TEMP_KEY_FILE" "$LOCAL_KEY_FILE"
    sudo chmod 644 "$LOCAL_KEY_FILE"
    sudo chown root:root "$LOCAL_KEY_FILE"
    # shellcheck source=/dev/null
    source "$LOCAL_KEY_FILE"
    ok "GEMINI_API_KEY eingerichtet: $LOCAL_KEY_FILE"

  else
    warn "GEMINI_API_KEY nicht kopiert — neuralpower nicht erreichbar oder Passwort falsch."
    warn "Manuell nachtraeglich einrichten:"
    warn "  sudo scp $REMOTE_HOST:$REMOTE_KEY_FILE $LOCAL_KEY_FILE"
  fi
fi

# ── 6. agy: Google OAuth Login ───────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Google OAuth Login fuer agy"
echo "========================================"
echo ""
echo "  agy benutzt Google Sign-In (kein API-Key)."
echo ""
echo "  Jetzt 'agy' starten und den angezeigten URL"
echo "  im Browser oeffnen um dich einzuloggen:"
echo ""
echo "    agy"
echo ""
echo "  Fuer SSH-Sessions wird der Login-URL direkt"
echo "  im Terminal angezeigt — im Browser oeffnen,"
echo "  einloggen, fertig."
echo ""

# Pruefe ob bereits eingeloggt
AGY_TEST=$(timeout 5 agy --print "echo LOGGED_IN" 2>&1 || true)
if echo "$AGY_TEST" | grep -q "LOGGED_IN"; then
  ok "agy bereits eingeloggt und funktionsbereit!"
else
  warn "agy noch nicht eingeloggt — bitte 'agy' starten und OAuth abschliessen."
fi

# ── 7. Abschluss ─────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Naechste Schritte"
echo "========================================"
echo ""
echo "  1. Login:          agy"
echo "     (URL im Browser oeffnen, Google-Account waehlen)"
echo ""
echo "  2. Test:           agy --print 'Sag Hallo'"
echo ""
echo "  3. Neue Shell:     source ~/.bashrc"
echo ""
echo "  Dokumentation: https://antigravity.google/docs/cli-overview"
echo ""
