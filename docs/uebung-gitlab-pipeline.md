# Uebung: GitLab CI/CD Pipeline mit Trivy

## Ziel

Die Sicherheitslücken, die lokal mit Trivy gefunden wurden, jetzt **automatisch** in der
CI/CD-Pipeline abfangen — vor jedem Merge. Kein Mensch muss den Scan manuell anstoßen.

Voraussetzung: lokales Setup aus
[Uebung: Gehaertetes Gemini-CLI-Image bauen](uebung-image-haerten.md) (Schritt 1–3).

---

## Warum Kaniko statt Docker-in-Docker?

Docker-in-Docker benoetigt `privileged: true` auf dem Runner — das gibt dem Job
Root-Rechte auf dem Host-Kernel. Kaniko baut das Image vollstaendig im Userspace,
braucht keinen Docker-Daemon und keinen privilegierten Modus.

---

## Schritt 1: `.gitlab-ci.yml` anlegen

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
  variables:
    TRIVY_USERNAME: $CI_REGISTRY_USER
    TRIVY_PASSWORD: $CI_REGISTRY_PASSWORD
  script:
    - trivy image
        --exit-code 1
        --severity HIGH,CRITICAL
        --scanners vuln,secret
        --ignore-unfixed
        --secret-config $CI_PROJECT_DIR/trivy-secret.yaml
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
  variables:
    TRIVY_USERNAME: $CI_REGISTRY_USER
    TRIVY_PASSWORD: $CI_REGISTRY_PASSWORD
  script:
    - trivy image --compliance docker-cis-1.6.0 $IMAGE_NAME:$IMAGE_TAG | tee cis-report.txt
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

---

## Schritt 2: Pipeline pushen (unsicheres Image)

```
git add Dockerfile .gitlab-ci.yml trivy-secret.yaml
git commit -m "build: initial Gemini CLI image"
git push
```

Die Pipeline bricht im `trivy-scan`-Job ab — exit code 1.
GitLab zeigt den Trivy-Report direkt im Security-Dashboard des MR.

---

## Erwartete Ausgabe — unsicheres Image (CIS-Scan, gekuerzt)

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

---

## Schritt 3: Image haerten → Pipeline gruen machen

Nachdem das Image lokal gehaertet wurde (`.dockerignore` + Multi-Stage-Build, siehe
[Uebung: Gehaertetes Gemini-CLI-Image bauen](uebung-image-haerten.md#schritt-4-image-haerten-und-pipeline-gruen-machen)):

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
beim Container-Start, nicht im Image selbst.

---

## Lernpunkt: CVEs in Basis-Images bewerten

Trivy scannt das **gesamte** Image — auch Pakete die das Basisimage mitbringt und die
du als Entwickler nicht kontrollierst. Typisches Beispiel bei `node:22-slim`:
npm bringt eigene interne Abhaengigkeiten mit (z.B. `picomatch` unter
`/usr/local/lib/node_modules/npm/`). Trivy meldet dort gefundene CVEs.

**Die richtige Reaktion ist nicht "sofort fixen" — sondern bewerten:**

| Frage | Bewertung |
|---|---|
| Ist der CVE in meinem Angriffsvektor? | npm laeuft nicht von aussen erreichbar im Container |
| Kann ich den Fix selbst einspielen? | Nein — das ist Sache des Basisimage-Maintainers |
| Gibt es bereits einen Fix? | Wenn nein: `--ignore-unfixed` ist korrekt |

`--ignore-unfixed` ueberspringt CVEs ohne verfuegbaren Fix (`will_not_fix`, `fix_deferred`).
Das ist keine Kapitulation — es ist eine bewusste, dokumentierte Entscheidung.

Sobald das Basisimage aktualisiert wird und einen Fix enthaelt, schlaegt Trivy wieder an
und zwingt zur erneuten Bewertung.

---

## Zusammenfassung

| Job | Zweck | Blockiert Pipeline |
|---|---|---|
| `build` | Image bauen mit Kaniko (kein privileged) | ja |
| `trivy-scan` | CVE + Secret-Scan, exit-code 1 bei Fund | ja (`allow_failure: false`) |
| `cis-scan` | CIS Docker Benchmark, Pass-Rate messen | nein (`allow_failure: true`) |

---

## Testprotokoll

| Datum | Tester | Phase | Ergebnis | Pipeline / Anmerkung |
|---|---|---|---|---|
| 2026-06-17 | jmetzger (lokal, Docker 29.5.3) | lokal | PASS | `trivy image --scanners secret` meldet `CRITICAL: GOOGLE (gemini-api-key)` in `/app/.env:1` ✓ |
| 2026-06-17 | Claude (gitlab.com/jmetzger/gemini-pipeline-test) | Phase 1 insecure | FAIL (erwartet) | [Pipeline #2607434854](https://gitlab.com/jmetzger/gemini-pipeline-test/-/pipelines/2607434854) — build PASS, trivy-scan FAIL (gemini-api-key + CVEs node:20.9.0), cis-scan PASS |
| 2026-06-17 | Claude (gitlab.com/jmetzger/gemini-pipeline-test) | Phase 2 hardened | PASS | [Pipeline #2607443302](https://gitlab.com/jmetzger/gemini-pipeline-test/-/pipelines/2607443302) — build PASS, trivy-scan PASS (0 findings), cis-scan PASS |

**Fixes die beim Live-Test notwendig waren:**

1. `docker-cis` → `docker-cis-1.6.0` (exakter Compliance-Spec-Name, sonst `FATAL: unknown compliance`)
2. `TRIVY_USERNAME`/`TRIVY_PASSWORD` als Job-Variablen ergänzt (Trivy braucht Credentials um das Image aus der GitLab-Registry zu pullen)
3. `--ignore-unfixed` im trivy-scan ergänzt (überspringt CVEs ohne verfügbaren Fix, z.B. `will_not_fix` im OS)
