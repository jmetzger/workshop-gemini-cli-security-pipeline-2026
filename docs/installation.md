# Installation — Gemini CLI Workshop-Setup

## Voraussetzungen

| Tool | Version | Zweck |
|---|---|---|
| Node.js | >= 18 | Gemini CLI laeuft auf Node |
| npm | beliebig | Paketmanager fuer Gemini CLI |
| Python 3 | >= 3.9 | Hermes-Regression-Tests |
| Docker | beliebig | Uebung: Image haerten (optional) |
| Trivy | beliebig | Uebung: CVE-Scan (optional) |

---

## Schnellstart: Installations-Script ausfuehren

```bash
bash scripts/install-gemini-cli.sh
```

Das Script prueft alle Voraussetzungen, installiert Gemini CLI global via npm
und gibt am Ende konkrete Hinweise fuer den API-Key-Setup aus.

---

## Was das Script tut

1. **Node.js pruefen** — bricht ab wenn < 18
2. **Gemini CLI installieren** — `npm install -g @google/gemini-cli`
3. **Python-Pakete installieren** — `pip install -r hermes-skill-regression/requirements.txt`
4. **Docker & Trivy pruefen** — Warnung falls nicht vorhanden (nicht blockierend)
5. **API-Key-Anleitung ausgeben**

---

## API-Key einrichten (nach dem Script)

1. Oeffne [https://aistudio.google.com/apikey](https://aistudio.google.com/apikey)
2. Erstelle einen neuen API-Key
3. Fuge ihn dauerhaft in dein Shell-Profil ein:

```bash
echo 'export GEMINI_API_KEY="DEIN_KEY_HIER"' >> ~/.bashrc
source ~/.bashrc
```

4. Test:

```bash
gemini --version
gemini "Sag Hallo"
```

---

## Node.js installieren (falls noch nicht vorhanden)

**Ubuntu/Debian:**
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**macOS:**
```bash
brew install node
```

**Windows:** Installer von [https://nodejs.org](https://nodejs.org) herunterladen.

---

## Trivy installieren (fuer CVE-Scan-Uebung)

**Ubuntu/Debian:**
```bash
sudo apt-get install -y wget apt-transport-https gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb generic main" \
  | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install -y trivy
```

**macOS:**
```bash
brew install trivy
```
