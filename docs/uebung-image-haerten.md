# Uebung: Gehaertetes Gemini-CLI-Image bauen

## Ziel

Wir patchen das offizielle Gemini-CLI-Sandbox-Image in zwei Stufen:

1. **Lokal** — absichtlich mit zwei nicht-offensichtlichen Sicherheitsluecken
2. **GitLab CI/CD** — Trivy-Scanner findet die Luecken automatisch
3. **Fix** — gehaertetes Image, das den Scan besteht

> **Realer Ansatz:** In der Praxis baut man kein Image von Grund auf neu, sondern
> nimmt das offizielle upstream-Image als `FROM`-Basis und patcht oder erweitert es.
> Googles Gemini-CLI-Sandbox liegt oeffentlich auf der Google Artifact Registry:
> `us-docker.pkg.dev/gemini-code-dev/gemini-cli/sandbox`

---

## Voraussetzungen

Docker und Trivy werden vom Installations-Script automatisch eingerichtet (`bash scripts/install-gemini-cli.sh`).

Nach der Installation muss die `docker`-Gruppe einmalig aktiviert werden — sonst schlaegt `docker build` mit "permission denied" fehl:

```bash
newgrp docker
```

> Das Script traegt deinen User zwar in die Gruppe ein, aber die aktuelle Shell-Session weiss davon noch nichts. `newgrp docker` aktiviert die Gruppe sofort ohne Logout.

---

## Schritt 1: Vorbereitung — Arbeitsverzeichnis anlegen

```bash
mkdir -p ~/gemini-image
cd ~/gemini-image
```

API-Key als Umgebungsvariable ablegen (wie er in einem echten Projekt vorkommen wuerde):

```bash
cat > .env <<'EOF'
GEMINI_API_KEY=AIzaSyRnFq8tLvPzX9dK3hJmW7oBqE1gY6cAi4z
EOF
```

Trivy kennt das Gemini-API-Key-Format nicht von Haus aus — wir legen eine eigene Erkennungsregel an:

```bash
cat > trivy-secret.yaml <<'EOF'
rules:
  - id: gemini-api-key
    category: GOOGLE
    title: Gemini API Key
    severity: CRITICAL
    regex: 'GEMINI_API_KEY\s*=\s*AIza[0-9A-Za-z\-_]{35}'
EOF
```

---

## Schritt 2: Unsicheres Image lokal bauen

Dockerfile anlegen — mit zwei absichtlichen Schwachstellen:

```
# vi Dockerfile

# Schwachstelle 1: selbst die aktuelle Version hat reale CVEs im Basisimage
FROM us-docker.pkg.dev/gemini-code-dev/gemini-cli/sandbox:0.47.0

WORKDIR /app

# Schwachstelle 2: kein .dockerignore — .env landet stillschweigend im Image
COPY . .
```

Image bauen:

```bash
docker build -t gemini-cli:insecure .
```

Kurz pruefen, dass die Datei wirklich im Image ist:

```bash
docker run --rm --entrypoint /bin/sh gemini-cli:insecure -c "cat /app/.env"
```

Der API-Key ist sichtbar — obwohl er nie bewusst "hinzugefuegt" wurde.

---

## Schritt 3: Lokal mit Trivy scannen

Trivy starten (kein Install noetig — laeuft als Container):

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd)/trivy-secret.yaml:/trivy-secret.yaml \
  aquasec/trivy:latest \
  image --severity HIGH,CRITICAL \
  --scanners vuln,secret \
  --secret-config /trivy-secret.yaml \
  gemini-cli:insecure
```

Trivy findet beide Schwachstellen. Erwartete Ausgabe (gekuerzt):

```
gemini-cli:insecure (debian 12.13)

Total: 228 (HIGH: 214, CRITICAL: 14)   ← OS-Pakete
Total:  11 (HIGH:  11, CRITICAL:  0)   ← Node.js-Pakete

┌───────────────────┬────────────────┬──────────┬──────────────┬─────────────────────┐
│ Library           │ Vulnerability  │ Severity │ Status       │ Title               │
├───────────────────┼────────────────┼──────────┼──────────────┼─────────────────────┤
│ zlib1g            │ CVE-2023-45853 │ CRITICAL │ will_not_fix │ Integer overflow /  │
│                   │                │          │              │ heap buffer overflow│
├───────────────────┼────────────────┼──────────┼──────────────┼─────────────────────┤
│ tar (package.json)│ CVE-2026-23745 │ HIGH     │ fixed        │ Arbitrary file      │
│                   │                │          │              │ overwrite via       │
│                   │                │          │              │ symlink poisoning   │
├───────────────────┼────────────────┼──────────┼──────────────┼─────────────────────┤
│ minimatch         │ CVE-2026-26996 │ HIGH     │ fixed        │ DoS via crafted     │
│ (package.json)    │                │          │              │ glob patterns       │
│ ...               │ ...            │ HIGH     │ fixed        │ ...                 │
└───────────────────┴────────────────┴──────────┴──────────────┴─────────────────────┘

app/.env (secrets)
===================
CRITICAL: GOOGLE (gemini-api-key)
 Gemini API Key
 app/.env:1
```

> **Lernpunkt CVEs:** Viele OS-Findings sind `will_not_fix` — Debian hat keinen Patch
> bereitgestellt. Das ist normal und kein Fehler des Images. Entscheidend ist die
> Unterscheidung: `fixed`-Findings koennen und sollen behoben werden, `will_not_fix`
> werden dokumentiert und akzeptiert.

---

> **GitLab CI/CD Pipeline** — Wie die Schwachstellen automatisch in der Pipeline abgefangen werden,
> ist in einer eigenen Uebung beschrieben:
> [Uebung: GitLab CI/CD Pipeline mit Trivy](uebung-gitlab-pipeline.md)

---

## Schritt 4: Image haerten und Pipeline gruen machen

### 4a: Secret-Leak beheben — `.dockerignore`

`.dockerignore` anlegen — verhindert, dass sensitive Dateien ins Image geraten:

```
# vi .dockerignore
.env
*.json.secret
service-account*.json
.git
*.log
```

Dockerfile bleibt auf `0.47.0` — der entscheidende Fix ist das `.dockerignore`:

```
# vi Dockerfile

FROM us-docker.pkg.dev/gemini-code-dev/gemini-cli/sandbox:0.47.0

WORKDIR /app

# Mit .dockerignore wird .env jetzt nicht mehr kopiert
COPY . .
```

Verifizieren — `.env` darf nicht mehr im Image sein:

```bash
docker build -t gemini-cli:secure .
docker run --rm --entrypoint /bin/sh gemini-cli:secure -c "cat /app/.env 2>&1 || echo 'nicht vorhanden'"
```

---

### 4b: Upstream-CVEs dokumentieren — `.trivyignore`

Nach dem Fix bleiben noch 17 CVEs offen: 6 in Debian-Paketen (`libgnutls30`, `libcap2`)
und 11 in Googles bundled npm-Paketen (`tar`, `minimatch`, `glob`, `cross-spawn`).
Alle stecken im upstream-Image — wir koennen sie nicht patchen ohne das Image
grundlegend umzubauen. Wir sind auf ein Google-Update angewiesen.

Die Loesung: `.trivyignore` — explizite, dokumentierte Akzeptanz des Restrisikos.

```
# vi .trivyignore

# CVEs in google/gemini-cli-sandbox:0.47.0 — not directly fixable by us.
# All findings are in Debian base packages or bundled npm packages of the
# upstream image. Upstream tracking:
#   https://github.com/google-gemini/gemini-cli/issues
# Accepted risk: sandboxed CLI tool, no user-facing HTTP endpoints.
# Review: when sandbox:0.48.0 releases stable.

# --- Debian OS packages (libgnutls30, libcap2) ---
CVE-2026-33845
CVE-2026-42010
CVE-2026-33846
CVE-2026-3833
CVE-2026-42009
CVE-2026-4878

# --- bundled npm: cross-spawn ---
CVE-2024-21538

# --- bundled npm: glob ---
CVE-2025-64756

# --- bundled npm: tar ---
CVE-2026-23745
CVE-2026-23950
CVE-2026-24842
CVE-2026-26960
CVE-2026-29786
CVE-2026-31802

# --- bundled npm: minimatch ---
CVE-2026-26996
CVE-2026-27903
CVE-2026-27904
```

> **Warum ist das kein Freifahrtschein?** `.trivyignore` zwingt zur expliziten
> Entscheidung pro CVE-ID. Blindes `--skip-vuln` wuerde alles verstecken —
> `.trivyignore` dokumentiert genau was akzeptiert wird und warum.

Jetzt nochmal lokal scannen — diesmal mit beiden Korrekturen:

```bash
trivy image \
  --severity HIGH,CRITICAL \
  --scanners vuln,secret \
  --ignore-unfixed \
  --secret-config trivy-secret.yaml \
  gemini-cli:secure
```

Erwartete Ausgabe:

```
Total: 0 (HIGH: 0, CRITICAL: 0)

No secrets detected.
```

Der API-Key wird zur Laufzeit per Umgebungsvariable uebergeben — nie ins Image gebacken:

```bash
docker run --rm \
  -e GEMINI_API_KEY=$GEMINI_API_KEY \
  gemini-cli:secure --version
```

Commit und Push — Pipeline soll jetzt durchlaufen:

```bash
git add Dockerfile .dockerignore .trivyignore
git commit -m "fix: harden image — add .dockerignore, document upstream CVEs in .trivyignore"
git push
```

Erwartete Pipeline-Ausgabe:

```
trivy-scan  PASSED — 0 HIGH/CRITICAL findings
cis-scan    CIS Pass-Rate: ~70% (7/10 Checks bestanden)
```

`USER node` ist im offiziellen Sandbox-Image bereits gesetzt — CIS 4.1 (Non-Root) ist damit behoben.
Die restlichen Failures (HEALTHCHECK, no-new-privileges) sind Konfigurationssache
beim Container-Start, nicht im Image selbst, und koennen in einem Folge-MR angegangen werden.

---

## Zusammenfassung

| Schwachstelle | Warum nicht offensichtlich | Wie gefunden | Fix |
|---|---|---|---|
| OS-CVEs (`will_not_fix`, ~222) | Debian stellt keinen Patch bereit | Trivy CVE-Scan | `--ignore-unfixed` in Pipeline |
| OS-CVEs `fixed` (`libgnutls30`, `libcap2`) + Node.js-CVEs (17 total) | Upstream-Abhaengigkeit in Googles Image | Trivy CVE-Scan | `.trivyignore` mit Begruendung |
| `GEMINI_API_KEY` in `.env` im Image | Wurde nie explizit `ADD`-ed — nur `COPY . .` | Trivy Secret-Scan | `.dockerignore` anlegen |
| Container laeuft als root | Standard bei vielen Base-Images | [CIS-Scan in GitLab CI](uebung-gitlab-pipeline.md) (Check 4.1) | Im offiziellen Image bereits `USER node` |

**Lernpunkt:** Security ist Risk Management, nicht Null-CVE-Zählen.
`--ignore-unfixed` und `.trivyignore` sind keine Auswege — sie erzwingen explizite,
dokumentierte Entscheidungen pro Finding. `COPY . .` kopiert alles, was im Verzeichnis liegt.
Die GitLab-Pipeline mit `--exit-code 1` ist das Sicherheitsnetz, das alle drei Faelle abfaengt.
