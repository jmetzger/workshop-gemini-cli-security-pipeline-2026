#!/usr/bin/env bash
# Installationsscript fuer Gemini CLI (Workshop-Setup)
# Ausfuehren: bash install-gemini-cli.sh
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
warn() { echo -e "${YELLOW}[!]${NC}   $*"; }
fail() { echo -e "${RED}[FEHLER]${NC} $*"; exit 1; }

echo "========================================"
echo "  Gemini CLI — Workshop Installations-Setup"
echo "========================================"
echo ""

# ── 1. Node.js pruefen (>= 18) ───────────────────────────────────────────────
echo ">> Node.js pruefen ..."
if ! command -v node &>/dev/null; then
  fail "Node.js nicht gefunden. Bitte zuerst Node.js >= 18 installieren: https://nodejs.org"
fi
NODE_VER=$(node --version | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VER" -lt 18 ]; then
  fail "Node.js $NODE_VER gefunden — benoetigt wird >= 18. Bitte updaten."
fi
ok "Node.js $(node --version) gefunden"

# ── 2. npm pruefen ───────────────────────────────────────────────────────────
if ! command -v npm &>/dev/null; then
  fail "npm nicht gefunden. Wird normalerweise mit Node.js mitgeliefert."
fi
ok "npm $(npm --version) gefunden"

# ── 3. npm Prefix auf user-writable Verzeichnis setzen (kein sudo noetig) ────
NPM_PREFIX="$HOME/.npm-global"
CURRENT_PREFIX=$(npm config get prefix 2>/dev/null || echo "")
if [[ "$CURRENT_PREFIX" == /usr/* ]] || [[ "$CURRENT_PREFIX" == /usr ]]; then
  echo ">> npm Prefix anpassen (aktuell: $CURRENT_PREFIX) ..."
  mkdir -p "$NPM_PREFIX"
  npm config set prefix "$NPM_PREFIX"
  ok "npm Prefix gesetzt: $NPM_PREFIX"

  # PATH fuer diese Session setzen
  export PATH="$NPM_PREFIX/bin:$PATH"
  warn "PATH nur fuer diese Session gesetzt. Dauerhaft eintragen: export PATH=\"\$HOME/.npm-global/bin:\$PATH\""
else
  export PATH="$NPM_PREFIX/bin:$PATH"
fi

# ── 4. Gemini CLI installieren ───────────────────────────────────────────────
echo ""
echo ">> Gemini CLI installieren ..."
npm install -g @google/gemini-cli
ok "Gemini CLI installiert: $(gemini --version 2>/dev/null || echo 'Version nicht auslesbar')"

# ── 5. Python pruefen (fuer Workshop-Tests) ──────────────────────────────────
echo ""
echo ">> Python pruefen (fuer Workshop-Test-Scripts) ..."
if command -v python3 &>/dev/null; then
  ok "Python $(python3 --version)"
else
  warn "Python 3 nicht gefunden — wird fuer die Hermes-Regression-Tests benoetigt."
  warn "Installation: https://www.python.org oder per Paketmanager (apt/brew)."
fi

# ── 6. Python-Abhaengigkeiten installieren ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQUIREMENTS="$SCRIPT_DIR/../hermes-skill-regression/requirements.txt"
if [ -f "$REQUIREMENTS" ]; then
  echo ""
  echo ">> Python-Pakete installieren (hermes-skill-regression) ..."
  python3 -m pip install -q -r "$REQUIREMENTS" && ok "Python-Pakete installiert" \
    || warn "pip install fehlgeschlagen — bitte manuell ausfuehren: pip install -r $REQUIREMENTS"
fi

# ── 7. Docker pruefen (optional, fuer Image-Uebungen) ───────────────────────
echo ""
echo ">> Docker pruefen (optional) ..."
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
  ok "Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
else
  warn "Docker nicht verfuegbar — wird fuer die Image-Haertungs-Uebung benoetigt."
fi

# ── 8. Trivy pruefen (optional, fuer CVE-Scan) ──────────────────────────────
if command -v trivy &>/dev/null; then
  ok "Trivy $(trivy --version | head -1)"
else
  warn "Trivy nicht gefunden — wird fuer den CVE-Scan benoetigt."
  warn "Installation: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
fi

# ── 9. Gemini CLI System-Policy anlegen (/etc/gemini-cli/settings.json) ──────
echo ""
echo ">> Gemini CLI System-Policy setzen ..."
sudo mkdir -p /etc/gemini-cli
sudo tee /etc/gemini-cli/settings.json > /dev/null <<'EOF'
{
  "security": {
    "disableYoloMode": true,
    "disableAlwaysAllow": true
  },
  "tools": {
    "sandbox": "docker",
    "core": ["ReadFile", "WriteFile", "RunCommand", "SearchFiles"],
    "sandboxNetworkAccess": false
  },
  "mcp": {
    "allowed": []
  },
  "logPrompts": false
}
EOF
sudo chmod 644 /etc/gemini-cli/settings.json
sudo chown root:root /etc/gemini-cli/settings.json
ok "System-Policy gesetzt: /etc/gemini-cli/settings.json"

# ── 10. API-Key system-weit setzen ──────────────────────────────────────────
GEMINI_KEY_FILE="/etc/profile.d/gemini-api.sh"
if [ -n "${GEMINI_API_KEY:-}" ]; then
  echo ""
  echo ">> API-Key system-weit eintragen ..."
  echo "export GEMINI_API_KEY='${GEMINI_API_KEY}'" | sudo tee "$GEMINI_KEY_FILE" > /dev/null
  sudo chmod 644 "$GEMINI_KEY_FILE"
  ok "API-Key eingetragen: $GEMINI_KEY_FILE (sichtbar fuer alle User)"
else
  warn "GEMINI_API_KEY nicht gesetzt — Key muss manuell eingetragen werden:"
  warn "  sudo bash -c \"echo \\\"export GEMINI_API_KEY='DEIN_KEY'\\\" > $GEMINI_KEY_FILE\""
fi

# ── 11. Abschluss-Hinweis ────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  Naechste Schritte"
echo "========================================"
echo ""
echo "  1. Google AI Studio aufrufen: https://aistudio.google.com/apikey"
echo "     -> API-Key erstellen, dann vor Script-Aufruf exportieren:"
echo "     export GEMINI_API_KEY='DEIN_KEY_HIER'"
echo "     bash scripts/install-gemini-cli.sh"
echo ""
echo "  2. Gemini CLI starten:"
echo "     gemini"
echo ""
echo "  3. System-Policy pruefen:"
echo "     gemini config list"
echo ""
echo "  Fertig! Viel Erfolg beim Workshop."
echo ""
