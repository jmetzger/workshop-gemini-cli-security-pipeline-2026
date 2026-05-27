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

Simulierten GCP-Service-Account anlegen (wie er in einem echten Projekt vorkommen wuerde):

```
cat > .env <<'EOF'
# Google Cloud credentials fuer lokale Entwicklung
GOOGLE_APPLICATION_CREDENTIALS=service-account.json
EOF

cat > service-account.json <<'EOF'
{
  "type": "service_account",
  "project_id": "my-gemini-project",
  "private_key_id": "abc123def456",
  "private_key": "-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA2a2rwplBQLzHPZe5TNJG\n-----END RSA PRIVATE KEY-----\n",
  "client_email": "gemini-runner@my-gemini-project.iam.gserviceaccount.com",
  "client_id": "112233445566778899",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
}
EOF
```

---

## Schritt 2: Unsicheres Image lokal bauen

Dockerfile anlegen — mit zwei absichtlichen Schwachstellen:

```
# vi Dockerfile

# Schwachstelle 1: veraltetes, ungepatchtes Basisimage mit bekannten CVEs
FROM node:18.0.0

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

# Schwachstelle 2: kein .dockerignore — .env und service-account.json
# landen stillschweigend im Image
COPY . .

RUN npm run build 2>/dev/null || true

USER node
ENTRYPOINT ["node", "bundle/gemini.js"]
```

Image bauen:

```
docker build -t gemini-cli:insecure .
```

Kurz pruefen, dass die Datei wirklich im Image ist:

```
docker run --rm gemini-cli:insecure cat /app/service-account.json
```

Der Service-Account-Key ist sichtbar — obwohl er nie bewusst "hinzugefuegt" wurde.

---

## Schritt 3: Lokal mit Trivy scannen

Trivy starten (kein Install noetig — laeuft als Container):

```
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest \
  image --severity HIGH,CRITICAL \
  --scanners vuln,secret \
  gemini-cli:insecure
```

Trivy findet beide Schwachstellen. Erwartete Ausgabe (gekuerzt):

```
gemini-cli:insecure (debian 11)

node:18.0.0 — CVE-Zusammenfassung
┌─────────────────┬──────────────────┬──────────┬────────────────────────────┐
│ Library         │ Vulnerability    │ Severity │ Title                      │
├─────────────────┼──────────────────┼──────────┼────────────────────────────┤
│ openssl         │ CVE-2022-0778    │ HIGH     │ Infinite loop in BN_mod_sqrt│
│ zlib            │ CVE-2022-37434   │ CRITICAL │ Heap buffer overflow        │
│ ...             │ ...              │ HIGH     │ ...                        │
└─────────────────┴──────────────────┴──────────┴────────────────────────────┘

Secrets found:
┌──────────────────────────────┬──────────┬──────────────────────────────────┐
│ File                         │ Severity │ Title                            │
├──────────────────────────────┼──────────┼──────────────────────────────────┤
│ /app/service-account.json    │ CRITICAL │ GCP Service Account Key detected │
│ /app/.env                    │ HIGH     │ Google credential file reference │
└──────────────────────────────┴──────────┴──────────────────────────────────┘
```

---

## Schritt 4: GitLab CI/CD Pipeline mit Trivy

Warum **Kaniko** statt Docker-in-Docker?
Docker-in-Docker benoetigt `privileged: true` auf dem Runner — das gibt dem Job
Root-Rechte auf dem Host-Kernel. Kaniko baut das Image vollstaendig im Userspace,
braucht keinen Docker-Daemon und keinen privilegierten Modus.

`.gitlab-ci.yml` anlegen:

```
# vi .gitlab-ci.yml
stages:
  - build
  - scan
  - release

variables:
  IMAGE_NAME: $CI_REGISTRY_IMAGE/gemini-cli
  IMAGE_TAG: $CI_COMMIT_SHORT_SHA

build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  script:
    - mkdir -p /kaniko/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"auth\":\"$(printf "%s:%s" "$CI_REGISTRY_USER" "$CI_REGISTRY_PASSWORD" | base64 | tr -d '\n')\"}}}" > /kaniko/.docker/config.json
    - /kaniko/executor
        --context $CI_PROJECT_DIR
        --dockerfile $CI_PROJECT_DIR/Dockerfile
        --destination $IMAGE_NAME:$IMAGE_TAG

trivy-scan:
  stage: scan
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    - trivy image
        --exit-code 1
        --severity HIGH,CRITICAL
        --scanners vuln,secret
        $IMAGE_NAME:$IMAGE_TAG
  artifacts:
    when: always
    reports:
      container_scanning: trivy-report.json
  allow_failure: false

cis-scan:
  stage: scan
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    - trivy image --compliance docker-cis $IMAGE_NAME:$IMAGE_TAG | tee cis-report.txt
    - |
      PASS=$(grep -c "PASS" cis-report.txt || true)
      FAIL=$(grep -c "FAIL" cis-report.txt || true)
      TOTAL=$((PASS + FAIL))
      RATE=0
      [ "$TOTAL" -gt 0 ] && RATE=$((PASS * 100 / TOTAL))
      echo "CIS Pass-Rate: $RATE% ($PASS/$TOTAL Checks bestanden)"
  artifacts:
    when: always
    paths:
      - cis-report.txt
  allow_failure: true
```

`cis-scan` nutzt `allow_failure: true` — beim ersten Durchlauf ist die Pass-Rate niedrig,
das soll die Pipeline nicht blockieren. Nach der Haertung kann man auf `false` umstellen.

Erwartete CIS-Ausgabe fuer das **unsichere** Image (gekuerzt):

```
CIS Benchmark: DKR.CIS-1.6.0
...
FAIL  DKR.CIS 4.1  Ensure that a user for the container has been created
      Reason: Container runs as root (no USER statement)

FAIL  DKR.CIS 4.6  Ensure that HEALTHCHECK instructions have been added
      Reason: No HEALTHCHECK defined

FAIL  DKR.CIS 4.9  Ensure that the user does not have unnecessary privileges
      Reason: no-new-privileges flag not set

PASS  DKR.CIS 4.2  Ensure that containers use trusted base images
...

CIS Pass-Rate: 40% (4/10 Checks bestanden)
```

Pipeline pushen:

```
git add Dockerfile .gitlab-ci.yml
git commit -m "build: initial Gemini CLI image"
git push
```

Die Pipeline bricht im `trivy-scan`-Job ab — exit code 1.
GitLab zeigt den Trivy-Report direkt im Security-Dashboard des MR.

---

## Schritt 5: Image haerten und Pipeline gruen machen

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

Dockerfile auf aktuelles, gepatchtes Basisimage umstellen:

```
# vi Dockerfile
FROM node:22-slim

WORKDIR /app

COPY --chown=node:node package*.json ./
RUN npm ci --omit=dev
COPY --chown=node:node . .
RUN npm run build 2>/dev/null || true

USER node
ENTRYPOINT ["node", "bundle/gemini.js"]
```

Service-Account-Credentials werden zur Laufzeit per Volume oder Secret uebergeben — nie ins Image gebacken:

```
docker run --rm \
  -v $HOME/.config/gcloud/application_default_credentials.json:/secrets/sa.json:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS=/secrets/sa.json \
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
| Veraltetes Basisimage `node:18.0.0` | Gepinnte Version wirkt "stabil" | Trivy CVE-Scan | `node:22-slim` verwenden |
| `service-account.json` im Image | Wurde nie explizit `ADD`-ed — nur `COPY . .` | Trivy Secret-Scan | `.dockerignore` anlegen |
| Container laeuft als root | node-Images starten als root wenn kein `USER` gesetzt | CIS-Scan (Check 4.1) | `USER node` ins Dockerfile |

**Lernpunkt:** `COPY . .` kopiert alles — auch Dateien, die niemand bewusst hinzufuegen wollte.
Ein gepinntes altes Image klingt nach "Reproduzierbarkeit", enthaelt aber ungepatchte CVEs.
Die GitLab-Pipeline mit `--exit-code 1` ist das Sicherheitsnetz, das beide Faelle abfaengt.
