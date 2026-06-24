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

Der API-Key wird zur Laufzeit per Umgebungsvariable uebergeben — nie ins Image gebacken:

```bash
docker run --rm \
  -e GEMINI_API_KEY=$GEMINI_API_KEY \
  gemini-cli:secure --version
```

Commit und Push — Pipeline soll jetzt durchlaufen:

```bash
git add Dockerfile .dockerignore
git commit -m "fix: harden image — update base version, add .dockerignore"
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
| 228 CVEs im aktuellen Image (14 CRITICAL) | Auch die neueste Version ist nicht CVE-frei | Trivy CVE-Scan | `will_not_fix` dokumentieren, `fixed` beheben |
| `GEMINI_API_KEY` in `.env` im Image | Wurde nie explizit `ADD`-ed — nur `COPY . .` | Trivy Secret-Scan | `.dockerignore` anlegen |
| Container laeuft als root | Standard bei vielen Base-Images | [CIS-Scan in GitLab CI](uebung-gitlab-pipeline.md) (Check 4.1) | Im offiziellen Image bereits `USER node` |

**Lernpunkt:** `COPY . .` kopiert alles — auch Dateien, die niemand bewusst hinzufuegen wollte.
Selbst das aktuelle offizielle Image hat reale CVEs — wichtig ist die Triage: `will_not_fix`
akzeptieren und dokumentieren, `fixed`-Findings aktiv angehen.
Die GitLab-Pipeline mit `--exit-code 1` ist das Sicherheitsnetz, das beides abfaengt.
