# DORA Artikel — Mapping zur Pipeline

DORA (Regulation EU 2022/2554) ist ein Resilienz-Gesetz, kein technischer Standard.
Es schreibt keine konkreten Tools oder Konfigurationen vor.

Was DORA verlangt: Risiken kennen, Massnahmen ergreifen, Entscheidungen begruenden
und dokumentieren. Die Pipeline produziert Artefakte die diesen Nachweis unterstuetzen.

**Wichtig:** "Pipeline-Artefakt vorhanden" bedeutet nicht automatisch DORA-konform.
Es bedeutet: ihr habt Evidenz die ein Auditor bewerten kann.

---

## Art. 6 — ICT Risk Management Framework

**Was DORA verlangt:**
Ein dokumentiertes Rahmenwerk fuer ICT-Risikomanagement — Rollen, Prozesse,
Verantwortlichkeiten fuer den Umgang mit ICT-Risiken.

**Was die Pipeline beitraegt:**
- Die Pipeline selbst ist ein Teil des Rahmenwerks
- Jeder MR = dokumentierte Entscheidung mit Begruendung
- MR-History = nachvollziehbarer Entscheidungspfad

**Was die Pipeline NICHT ersetzt:**
- Governance-Dokumente (wer ist verantwortlich?)
- Risikoregister auf Unternehmensebene

---

## Art. 8 — Identifikation

**Was DORA verlangt:**
ICT-Assets identifizieren und katalogisieren. Risiken fuer diese Assets bewerten
und dokumentieren.

**Was die Pipeline beitraegt:**

| Artefakt | Inhalt | Aufbewahrung |
|---|---|---|
| `baseline-trivy.json` | CVE-Liste mit Severity zum Zeitpunkt X | 1 Jahr |
| `baseline-grype.json` | Risk Score (CVSS + EPSS + KEV) | 1 Jahr |
| `sbom.json` (CycloneDX) | Alle Pakete und Abhaengigkeiten im Image | 1 Jahr |

Der SBOM ist der Kern fuer Art. 8 — er zeigt was im Asset steckt.

**Pipeline-Befehl:**
```
trivy image --format cyclonedx --output sbom.json $IMAGE
```

---

## Art. 9 — Schutz und Praevention

**Was DORA verlangt:**
Angemessene Schutzmassnahmen implementieren. Access Control, Patch Management,
Haertung von Systemen. Massnahmen muessen dokumentiert und begruendet sein.

**Was die Pipeline beitraegt:**

| Massnahme | Nachweis | Pipeline-Artefakt |
|---|---|---|
| Container-Haertung | CIS Docker Benchmark | `cis-report.html` |
| Non-root Execution | CIS Check 1.1 PASS | `cis-report.html` |
| Keine gefaehrlichen Capabilities | `--cap-drop ALL` dokumentiert | MR-Beschreibung |
| Read-only Filesystem | Guardrail-Test PASS | `guardrail-test.log` |
| Tool-Allowlist oder begruendete Blocklist | `settings.json` + `guardrail-decision.md` | Repo-Inhalt |

**Pipeline-Befehl:**
```
trivy image --compliance docker-cis --format template \
  --template "@contrib/html.tpl" --output cis-report.html $IMAGE
```

**Hinweis Allowlist vs. Blocklist:**
DORA schreibt keinen der beiden Ansaetze vor. Wer Blocklist verwendet,
muss in `docs/guardrail-decision.md` begruenden warum das fuer das
eigene Risikoprofil ausreicht.

---

## Art. 10 — Erkennung

**Was DORA verlangt:**
Mechanismen zur Erkennung von Anomalien und Vorfaellen. Monitoring.

**Was die Pipeline beitraegt:**
- Pipeline schlaegt bei neuen CVEs (CRITICAL/HIGH) automatisch an
- Jeder Push triggert einen Scan — neue Schwachstellen werden innerhalb
  des naechsten Commits erkannt, nicht erst beim naechsten manuellen Audit

**Was die Pipeline NICHT ersetzt:**
- Runtime-Monitoring (Falco, etc.) — die Pipeline prueft das Image, nicht
  den laufenden Container
- SIEM-Integration

---

## Art. 13 — Testen der digitalen Betriebsstabilitaet

**Was DORA verlangt:**
Regelmaessiges Testen von ICT-Tools und Sicherheitsmassnahmen.
Fuer bedeutende Institute: TLPT (Threat-Led Penetration Testing).

**Was die Pipeline beitraegt:**

| Test | Haeufigkeit | Artefakt |
|---|---|---|
| Guardrail-Tests (Negativ) | Bei jedem MR | Pipeline-Log |
| Behavioral Tests | Bei jedem MR | `behavioral-test.log` |
| Injection-Tests | Bei jedem MR | `injection-test.log` |
| CIS Benchmark | Bei jedem Build | `cis-report.html` |

**Was die Pipeline NICHT ersetzt:**
- TLPT (Threat-Led Penetration Testing) — das ist ein gesondertes Verfahren
  mit externen Testern, nicht durch automatisierte Pipeline abgedeckt

---

## Art. 19 — Management von ICT-Drittparteirisiken

**Was DORA verlangt:**
Risiken durch externe ICT-Anbieter dokumentieren und managen.
Fuer Drittparteisoftware: wissen was drin ist, Schwachstellen kennen.

**Was die Pipeline beitraegt:**

| Anforderung | Artefakt | Begruendung |
|---|---|---|
| Software-Inventar des Drittanbieter-Images | `sbom.json` | Zeigt alle Pakete im Google-Image |
| Bekannte Schwachstellen dokumentiert | `baseline-trivy.json` | CVE-Liste mit Datum |
| Risikobewertung | `baseline-grype.json` | Risk Score 0-10 |
| Verbesserungsnachweis | MR-History + Metriken-Tabelle | Vorher/Nachher belegt |

Das offizielle Gemini CLI Image (`ghcr.io/google/gemini-cli`) ist Drittparteisoftware
von Google. Der SBOM-Prozess erfuellt die Dokumentationspflicht aus Art. 19.

---

## Zusammenfassung: Was fehlt noch fuer vollstaendige DORA-Compliance

Die Pipeline liefert technische Evidenz. Folgendes muss organisatorisch ergaenzt werden:

| Luecke | Wer | Wo |
|---|---|---|
| ICT Risk Management Framework (Art. 6) | CISO / Management | Governance-Dokument |
| Risikoregister (Art. 8) | Risk Manager | GRC-Tool |
| Incident Response Prozess (Art. 11) | IT-Betrieb | Playbook |
| TLPT (Art. 13, nur bedeutende Institute) | Extern | Beauftragter Tester |
| Vertragsklauseln mit Google (Art. 19) | Legal / Einkauf | Vertrag |
