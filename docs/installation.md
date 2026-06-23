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

Script: [`scripts/install-gemini-cli.sh`](../scripts/install-gemini-cli.sh)

```bash
bash scripts/install-gemini-cli.sh
```

Das Script prueft alle Voraussetzungen, installiert Gemini CLI global via npm
und gibt am Ende konkrete Hinweise fuer den API-Key-Setup aus.

> **Hinweis zu `--allow-scripts`:** npm blockiert seit Version 7 standardmaessig
> Post-Install-Scripts von Paketen (Schutz vor Supply-Chain-Angriffen). Zwei
> Abhaengigkeiten von Gemini CLI benoetigen solche Scripts legitimerweise:
> `@github/keytar` (kompiliert native Binaries fuer System-Keychain) und
> `node-pty` (Pseudo-Terminal-Emulation). Das Script erlaubt sie explizit nur
> fuer diese zwei Pakete — alle anderen bleiben geblockt.

---

## Was das Script tut

1. **Node.js pruefen** — bricht ab wenn < 18
2. **Gemini CLI installieren** — `npm install -g @google/gemini-cli`
3. **Python-Pakete installieren** — `pip install -r hermes-skill-regression/requirements.txt`
4. **Docker installieren** — falls nicht vorhanden: automatisch via offizielles docker.com-Repo (Ubuntu/Debian) oder Homebrew-Hinweis (macOS)
5. **Trivy installieren** — falls nicht vorhanden: automatisch via aquasecurity-Repo (Ubuntu/Debian) oder Homebrew (macOS)
6. **Gemini CLI System-Policy setzen** — `/etc/gemini-cli/settings.json`
7. **API-Key system-weit eintragen** — `/etc/profile.d/gemini-api.sh`

> **Hinweis:** Das Script darf **nicht als root** ausgefuehrt werden — einzelne Schritte rufen intern `sudo` auf. Start immer als normaler User.

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

## Docker & Trivy installieren

Das Installations-Script erledigt das automatisch:

```bash
bash scripts/install-gemini-cli.sh
```

Falls eine manuelle Installation noetig ist:

**Docker (Ubuntu/Debian) — offizielles docker.com-Repo:**
```bash
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker "$USER"
```

**Trivy (Ubuntu/Debian) — aquasecurity-Repo:**
```bash
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/trivy.gpg > /dev/null
echo "deb https://aquasecurity.github.io/trivy-repo/deb generic main" \
  | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update && sudo apt-get install -y trivy
```

**macOS:**
```bash
brew install --cask docker
brew install trivy
```
