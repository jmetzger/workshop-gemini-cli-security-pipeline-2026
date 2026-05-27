# Uebung: Gehaertetes Gemini-CLI-Image bauen

## Ziel

Wir bauen das Gemini-CLI-Image in zwei Stufen:

1. **Lokal** — absichtlich mit zwei Sicherheitsluecken
2. **GitLab CI/CD** — Trivy-Scanner findet die Luecken automatisch
3. **Fix** — gehärtetes Image, das den Scan besteht

---

## Schritt 1: Unsicheres Image lokal bauen

```
cd
mkdir -p gemini-image
cd gemini-image
git clone https://github.com/google-gemini/gemini-cli src
cd src
```

Dockerfile anlegen — mit zwei absichtlichen Schwachstellen:

```
# vi Dockerfile
FROM node:22

WORKDIR /app

# Schwachstelle 1: API-Key fest im Image eingebaut
ENV GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
RUN npm run build 2>/dev/null || true

# Schwachstelle 2: kein USER-Directive — laeuft als root
ENTRYPOINT ["node", "bundle/gemini.js"]
```

Image bauen:

```
docker build -t gemini-cli:insecure .
```

---

## Schritt 2: Lokal mit Trivy scannen

Trivy starten (einmalig als Container, kein Install noetig):

```
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest \
  image --severity HIGH,CRITICAL gemini-cli:insecure
```

Trivy findet beide Probleme. Erwartete Ausgabe (gekuerzt):

```
gemini-cli:insecure (debian 12.x)
...
CRITICAL  Secret detected: GEMINI_API_KEY in ENV directive
HIGH      Container runs as root (no USER instruction found)
```

Secret-Scan explizit:

```
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest \
  image --scanners secret gemini-cli:insecure
```

Erwarteter Fund:

```
SECRET  ENV  GEMINI_API_KEY  Generic API Key detected
```

---

## Schritt 3: GitLab CI/CD Pipeline mit Trivy

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
  image: docker:24
  services:
    - docker:24-dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $IMAGE_NAME:$IMAGE_TAG .
    - docker push $IMAGE_NAME:$IMAGE_TAG

trivy-scan:
  stage: scan
  image:
    name: aquasec/trivy:latest
    entrypoint: [""]
  script:
    - trivy image
        --exit-code 1
        --severity HIGH,CRITICAL
        --scanners vuln,secret,misconfig
        $IMAGE_NAME:$IMAGE_TAG
  allow_failure: false
```

Pipeline pushen:

```
git add Dockerfile .gitlab-ci.yml
git commit -m "build: initial Gemini CLI image"
git push
```

Die Pipeline bricht im `trivy-scan`-Job ab — exit code 1 wegen der zwei Schwachstellen.

---

## Schritt 4: Image haerten und Pipeline gruen machen

Dockerfile ersetzen — beide Luecken geschlossen:

```
# vi Dockerfile
FROM node:22-slim

WORKDIR /app

# Kein GEMINI_API_KEY mehr im Image — wird zur Laufzeit uebergeben
COPY --chown=node:node package*.json ./
RUN npm ci --omit=dev
COPY --chown=node:node . .
RUN npm run build 2>/dev/null || true

# Laeuft als unprivilegierter node-User
USER node

ENTRYPOINT ["node", "bundle/gemini.js"]
```

API-Key wird nur noch zur Laufzeit gesetzt:

```
docker run --rm -e GEMINI_API_KEY=<dein-key> gemini-cli:secure --version
```

Commit und Push — Pipeline soll jetzt durchlaufen:

```
git add Dockerfile
git commit -m "fix: remove hardcoded secret, add USER directive"
git push
```

Erwartete Pipeline-Ausgabe:

```
trivy-scan  PASSED — 0 HIGH/CRITICAL findings
```

---

## Zusammenfassung

| Schwachstelle | Wie entdeckt | Fix |
|---|---|---|
| API-Key in `ENV` | Trivy Secret-Scan | Key nur per `-e` zur Laufzeit uebergeben |
| Root-User im Container | Trivy Misconfiguration | `USER node` im Dockerfile |

**Regel:** Kein Secret gehoert ins Image. Kein Prozess laeuft als root.
Die GitLab-Pipeline mit `--exit-code 1` sorgt dafuer, dass ein unsicheres Image
niemals in die Registry gepusht wird.
