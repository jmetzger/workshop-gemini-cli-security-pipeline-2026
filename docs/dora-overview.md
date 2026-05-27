# Absicherung der Gemini CLI als Docker-Sandbox — DORA-Einordnung

> **Legende**
> ⭐ = im Training praktisch behandelt (Hands-on)
> ohne Stern = nur kurz eingeordnet, kein eigenes Lab

---

## Uebersicht

![DORA Uebersicht](/images/dora-overview.svg)

| # | DORA Artikel | Handlungsfeld | Workshop | Kern-Artefakt |
|---|---|---|---|---|
| 1 | Art. 8 | Identifikation | ⭐ | ai-bom.json, sbom.json, REVISIONS.md |
| 2 | Art. 9 | Schutz &amp; Haertung | ⭐ | CIS-Report, Guardrail-Tests |
| 3 | Art. 10 | Detektion | — | Pipeline-Logs |
| 4 | Art. 24/25 | Resilienz-Testing | ⭐ | trivy.json, grype.json, cis-report.html |
| 5 | Art. 28/30 | Drittparteienrisiko | — | sbom.json, DPA |
| 6 | Art. 17/18/19 | Incident Management | — | Playbook |

---

## Was DORA von uns verlangt — und warum das hier relevant ist

DORA (Regulation EU 2022/2554) ist ein Resilienzgesetz fuer Finanzunternehmen.
Es schreibt keine konkreten Tools vor, aber es verlangt:
Risiken kennen, Massnahmen ergreifen, Entscheidungen begruenden und dokumentieren.

Gemini CLI als KI-Tool im Unternehmenseinsatz ist ein **ICT-Asset** und faellt
damit unter das Risikomanagement-Framework. Wer es im Produktionsbetrieb einsetzt,
muss nachweisen koennen, dass es sicher konfiguriert ist — und dass dieser Zustand
regelmaessig geprueft wird.

Dieser Workshop liefert genau diesen Nachweis.

---

## Die sechs Handlungsfelder

### 1 — Ueberblick behalten ⭐
**(DORA Art. 8 — Identifikation)**

Wissen was laeuft: Welches Image, welche Version, welche Skills, welcher Endpoint.

Das Inventar besteht aus drei Artefakten:

| Artefakt | Inhalt |
|---|---|
| `ai-bom.json` | Image-Digest, Skill-Hashes, Modell, Endpoint |
| `sbom.json` (CycloneDX) | Alle Pakete und Abhaengigkeiten im Image |
| `REVISIONS.md` | Aenderungshistorie — jede neue Version ergibt eine Zeile |

Die GitLab-CI schreibt bei jedem Build automatisch eine neue Zeile in `REVISIONS.md`
(neueste oben). Kein manueller Aufwand, keine vergessenen Eintraege.

**Einordnung im Workshop:**
Kein eigenes Modul — diese Artefakte entstehen als Nebenprodukt von Modul 2
(Pipeline baut sie) und werden in Modul 4 geprueft (Pipeline prueft sie).

---

### 2 — Schuetzen und Haerten ⭐
**(DORA Art. 9 — Schutz & Praevention)**

Das ist der Workshop-Kern — das eigentliche Tun.

Vier Ebenen der Haertung:

| Ebene | Massnahme | Nachweis |
|---|---|---|
| Image | Schlankeres Base Image, Non-root User | CIS-Report, CVE-Reduktion |
| Sandbox | `--network none`, `--read-only`, `--cap-drop ALL` | Guardrail-Tests |
| Tool-Allowlist | `settings.json` — nur erlaubte Tools koennen aufgerufen werden | Guardrail-Test PASS |
| Egress | Kein ausgehender Traffic ausser explizit erlaubtem Endpoint | Negativ-Test PASS |

**LLM-Injections** werden durch technische Controls verhindert (Ebene 1+2),
nicht durch Instruktionen an das Modell (GEMINI.md ist kein Hard Block).

Skills werden versioniert und vor dem Merge reviewed — Aenderungen an
einem Skill sind nachvollziehbar, kein unbemerktes Umschreiben von Verhalten.

**Einordnung im Workshop:**
Grosser Hands-on-Block an Tag 1 (Grundlagen) und Tag 2 (Pipeline als Verbesserungsmotor).
Jeder Merge Request = ein messbarer Verbesserungsschritt.

---

### 3 — Mitschreiben
**(DORA Art. 10 — Detektion)**

Protokollieren, wer das Tool nutzt und was es tut — damit man bei einem
Vorfall nachvollziehen kann, was passiert ist.

Was minimal geloggt werden sollte:

- Wer hat den Container gestartet? (User, Zeitstempel)
- Welcher Prompt wurde uebergeben?
- Welche Tool-Calls hat der Agent ausgefuehrt?
- Welcher Output wurde zurueckgegeben?

Die Pipeline erkennt neue CVEs automatisch bei jedem Push — das ist die
einfachste Form von Detektion. Runtime-Monitoring (Falco o.ae.) ersetzt
die Pipeline nicht und wird von ihr auch nicht ersetzt.

**Einordnung im Workshop:**
Kein eigenes Lab — wird kurz eingeordnet. Die Pipeline-Logs sind bereits
ein erster Detektionsmechanismus. Vollstaendiges Audit-Logging ist
ein organisatorisches Thema das ueber den Workshop hinausgeht.

---

### 4 — Regelmaessig pruefen ⭐
**(DORA Art. 24/25 — Resilienz-Testing)**

Nachweisen dass die Haertung wirkt — und dass sie nach Aenderungen noch wirkt.

Das ist der Nachweis zu Punkt 2. Beide gehoeren zusammen:
Punkt 2 ist das Tun, Punkt 4 ist das Belegen des Tuns.

| Test | Frequenz | Artefakt |
|---|---|---|
| CVE-Scan (Trivy + Grype) | Bei jedem MR automatisch | `trivy.json`, `grype.json` |
| CIS Docker Benchmark | Bei jedem Build | `cis-report.html` |
| Guardrail-Tests (Negativ) | Bei jedem MR automatisch | Pipeline-Log |
| Injection-Tests | Bei jedem MR automatisch | `injection-test.log` |
| Behavioral Tests (Golden) | Bei jedem MR automatisch | `behavioral-test.log` |

**Mindestens jaehrlich** muessen die Ergebnisse dokumentiert und bewertet werden.
Die Pipeline produziert die Artefakte bei jedem Lauf — die jaehrliche Bewertung
ist ein organisatorischer Schritt (wer schaut drauf, wer entscheidet?).

**Einordnung im Workshop:**
Hands-on in Modul 4 (Tag 2 Nachmittag). TN simulieren eine Regression
(Guardrail wird bewusst entfernt) und sehen wie die Pipeline es abfaengt.

---

### 5 — Google als externen Dienstleister absichern
**(DORA Art. 28/30 — Drittparteienrisiko)**

Gemini CLI ist Software von Google — und Google ist damit ein ICT-Drittanbieter
im Sinne von DORA.

Zwei Aspekte:

**Vertrag und Datenschutz**
- Richtiger Tarif / richtiges Produkt: EU-Datenspeicherung, kein Training
  mit Unternehmensdaten, DPA (Data Processing Agreement) vorhanden
- Das ist eine Legal- und Einkaufsentscheidung, keine technische

**Plan B (Exit-Strategie)**
- Was passiert wenn Google den Dienst aendert oder einstellt?
- Welcher Alternativ-Endpoint ist im Ernstfall verfuegbar?
- Wie lange dauert eine Migration?

Der SBOM (`sbom.json`) dokumentiert was im Google-Image steckt — das ist
die technische Grundlage fuer die Drittparteien-Risikodokumentation.

**Einordnung im Workshop:**
Kein Lab — wird als Kontext eingeordnet. Die Vertragsebene liegt ausserhalb
des technischen Workshops.

---

### 6 — Probleme erkennen und melden
**(DORA Art. 17/18/19 — Incident-Management)**

Vorher festlegen, was als Stoerung gilt — nicht erst wenn es brennt.

Mindest-Definitionen die jedes Team haben sollte:

| Frage | Beispiel-Antwort |
|---|---|
| Was ist ein Sicherheitsvorfall? | Neues CRITICAL CVE mit EPSS > 0.5 |
| Was ist eine Funktionsstoerung? | Guardrail-Test FAIL nach Update |
| Was ist meldepflichtig (DORA)? | Ausfall > 4h oder Datenverlust |
| Wer wird wann informiert? | CISO innerhalb 24h, BaFin gemaess DORA Art. 19 |

Die Pipeline kann erkennen (CVE-Alarm, Test-Fehler), aber sie kann nicht
entscheiden ob etwas meldepflichtig ist. Diese Entscheidung braucht
einen definierten Prozess — ein Playbook.

**Einordnung im Workshop:**
Kein Lab — wird als Rahmenbedingung eingeordnet. Teilnehmer verlassen
den Workshop mit dem Wissen, was sie noch organisatorisch erarbeiten muessen.

---

## Roter Faden

```
Wissen was laeuft   (Art. 8)  →  Inventar, SBOM, Digest
Haerten             (Art. 9)  →  Image, Sandbox, Allowlist, Egress
Mitschreiben        (Art. 10) →  Logs, Audit-Trail
Testen              (Art. 24) →  CVE-Scan, CIS, Guardrails, Injection
Anbieter sichern    (Art. 28) →  Vertrag, Exit-Plan, SBOM-Pflicht
Vorfaelle erkennen  (Art. 17) →  Definition, Playbook, Meldepflicht
```

**Punkt 2 (Haerten) ist das Tun — Punkt 4 (Testen) ist das Belegen.**
Diese beiden Handlungsfelder gehoeren zusammen und bilden den Kern des Workshops.

---

## Was die Pipeline liefert — und was sie nicht ersetzt

| Was die Pipeline liefert | Was organisatorisch ergaenzt werden muss |
|---|---|
| Technische Evidenz (Artefakte, Logs) | ICT Risk Management Framework (Art. 6) |
| Automatischer CVE-Alarm | Risikoregister auf Unternehmensebene (Art. 8) |
| Guardrail-Test-Logs | Incident Response Playbook (Art. 11) |
| SBOM und CIS-Reports | Vertragsklauseln mit Google (Art. 28) |
| MR-History als Aenderungsprotokoll | TLPT (nur bedeutende Institute, Art. 25) |

> "Pipeline-Artefakt vorhanden" bedeutet nicht automatisch DORA-konform.
> Es bedeutet: ihr habt Evidenz die ein Auditor bewerten kann.

Weitergehende Details zu jedem DORA-Artikel: [dora-mapping.md](dora-mapping.md)
