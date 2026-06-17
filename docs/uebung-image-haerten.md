# Uebung: Gehaertetes Gemini-CLI-Image bauen

## Ziel

Wir bauen das Gemini-CLI-Image in zwei Stufen:

1. **Lokal** — absichtlich mit zwei nicht-offensichtlichen Sicherheitsluecken
2. **GitLab CI/CD** — Trivy-Scanner findet die Luecken automatisch
3. **Fix** — gehaertetes Image, das den Scan besteht

---

## Schritt 1: Vorbereitung — Projektstruktur anlegen

```
cd
mkdir -p gemini-image
cd gemini-image
git clone https://github.com/google-gemini/gemini-cli src
cd src
```

API-Key als Umgebungsvariable ablegen (wie er in einem echten Projekt vorkommen wuerde):

```
cat > .env <<'EOF'
GEMINI_API_KEY=AIzaSyRnFq8tLvPzX9dK3hJmW7oBqE1gY6cAi4z
EOF
```

Trivy kennt den Gemini-API-Key-Format nicht von Haus aus — wir legen eine eigene Erkennungsregel an:

```
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

# Schwachstelle 1: veraltetes, ungepatchtes Basisimage mit bekannten CVEs
FROM node:20.9.0

WORKDIR /app

# Workspace package.json Dateien fuer npm ci (gemini-cli ist ein Monorepo)
COPY package*.json ./
COPY packages/cli/package*.json ./packages/cli/
COPY packages/core/package*.json ./packages/core/
COPY packages/devtools/package*.json ./packages/devtools/
COPY packages/sdk/package*.json ./packages/sdk/
COPY packages/test-utils/package*.json ./packages/test-utils/
COPY packages/a2a-server/package*.json ./packages/a2a-server/
COPY packages/vscode-ide-companion/package*.json ./packages/vscode-ide-companion/
COPY packages/vscode-ide-companion/scripts/ ./packages/vscode-ide-companion/scripts/

RUN HUSKY=0 npm ci --ignore-scripts

# Schwachstelle 2: kein .dockerignore — .env landet stillschweigend im Image
COPY . .

RUN HUSKY=0 npm run bundle

USER node
ENTRYPOINT ["node", "bundle/gemini.js"]
```

Image bauen:

```
docker build -t gemini-cli:insecure .
```

Kurz pruefen, dass die Datei wirklich im Image ist:

```
docker run --rm --entrypoint /bin/sh gemini-cli:insecure -c "cat /app/.env"
```

Der API-Key ist sichtbar — obwohl er nie bewusst "hinzugefuegt" wurde.

---

## Schritt 3: Lokal mit Trivy scannen

Trivy starten (kein Install noetig — laeuft als Container):

```
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
gemini-cli:insecure (debian 12.2)

node:20.9.0 — CVE-Zusammenfassung
┌─────────────────┬──────────────────┬──────────┬────────────────────────────┐
│ Library         │ Vulnerability    │ Severity │ Title                      │
├─────────────────┼──────────────────┼──────────┼────────────────────────────┤
│ openssl         │ CVE-2026-31789   │ CRITICAL │ Heap buffer overflow        │
│ openssh-client  │ CVE-2024-6387    │ HIGH     │ regreSSHion: RCE/DoS       │
│ ...             │ ...              │ HIGH     │ ...                        │
└─────────────────┴──────────────────┴──────────┴────────────────────────────┘

app/.env (secrets)
===================
CRITICAL: GOOGLE (gemini-api-key)
 Gemini API Key
 app/.env:1
```

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
node_modules
*.log
```

Dockerfile auf Multi-Stage-Build mit aktuellem, gepatchtem Basisimage umstellen.
Der Multi-Stage-Ansatz hat einen weiteren Sicherheitsvorteil: Stage 2 erhaelt
nur die gepackten npm-Artefakte — selbst wenn versehentlich sensitive Dateien
in den Build-Kontext geraten, landen sie nie in der finalen Runtime-Stage.

```
# vi Dockerfile

# ---- Stage 1: Builder ----
FROM node:22-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends git \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY package*.json ./
COPY packages/cli/package*.json ./packages/cli/
COPY packages/core/package*.json ./packages/core/
COPY packages/devtools/package*.json ./packages/devtools/
COPY packages/sdk/package*.json ./packages/sdk/
COPY packages/test-utils/package*.json ./packages/test-utils/
COPY packages/a2a-server/package*.json ./packages/a2a-server/
COPY packages/vscode-ide-companion/package*.json ./packages/vscode-ide-companion/
COPY packages/vscode-ide-companion/scripts/ ./packages/vscode-ide-companion/scripts/

RUN HUSKY=0 npm ci --ignore-scripts

COPY packages/ ./packages/
COPY tsconfig*.json ./
COPY eslint.config.js ./
COPY scripts/ ./scripts/
COPY esbuild.config.js ./

RUN HUSKY=0 npm run build && \
    npm pack -w packages/core --pack-destination packages/core/dist/ && \
    npm pack -w packages/cli --pack-destination packages/cli/dist/

# ---- Stage 2: Runtime ----
FROM node:22-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
  git curl socat ca-certificates \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/share/npm-global \
  && chown -R node:node /usr/local/share/npm-global
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

USER node

COPY --from=builder --chown=node:node /build/packages/cli/dist/google-gemini-cli-*.tgz /tmp/gemini-cli.tgz
COPY --from=builder --chown=node:node /build/packages/core/dist/google-gemini-cli-core-*.tgz /tmp/gemini-core.tgz

RUN npm install -g /tmp/gemini-core.tgz \
  && npm install -g /tmp/gemini-cli.tgz \
  && gemini --version > /dev/null \
  && npm cache clean --force \
  && rm -f /tmp/gemini-*.tgz

ENTRYPOINT ["/usr/local/share/npm-global/bin/gemini"]
```

Der API-Key wird zur Laufzeit per Umgebungsvariable uebergeben — nie ins Image gebacken:

```
docker run --rm \
  -e GEMINI_API_KEY=$GEMINI_API_KEY \
  gemini-cli:secure --version
```

Commit und Push — Pipeline soll jetzt durchlaufen:

```
git add Dockerfile .dockerignore
git commit -m "fix: harden image — update base, add .dockerignore"
git push
```

Erwartete Pipeline-Ausgabe:

```
trivy-scan  PASSED — 0 HIGH/CRITICAL findings
cis-scan    CIS Pass-Rate: ~70% (7/10 Checks bestanden)
```

`USER node` im Dockerfile behebt CIS 4.1 (Non-Root) — der wichtigste Check.
Die restlichen Failures (HEALTHCHECK, no-new-privileges) sind Konfigurationssache
beim Container-Start, nicht im Image selbst, und koennen in einem Folge-MR angegangen werden.

---

## Zusammenfassung

| Schwachstelle | Warum nicht offensichtlich | Wie gefunden | Fix |
|---|---|---|---|
| Veraltetes Basisimage `node:20.9.0` | Gepinnte Version wirkt "stabil" | Trivy CVE-Scan | `node:22-slim` verwenden |
| `GEMINI_API_KEY` in `.env` im Image | Wurde nie explizit `ADD`-ed — nur `COPY . .` | Trivy Secret-Scan | `.dockerignore` anlegen |
| Container laeuft als root | node-Images starten als root wenn kein `USER` gesetzt | [CIS-Scan in GitLab CI](uebung-gitlab-pipeline.md) (Check 4.1) | `USER node` ins Dockerfile |

**Lernpunkt:** `COPY . .` kopiert alles — auch Dateien, die niemand bewusst hinzufuegen wollte.
Ein gepinntes altes Image klingt nach "Reproduzierbarkeit", enthaelt aber ungepatchte CVEs.
Die GitLab-Pipeline mit `--exit-code 1` ist das Sicherheitsnetz, das beide Faelle abfaengt.
