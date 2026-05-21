# Guardrail-Entscheidung: Tool-Permissions

**Datum:** ____________________
**Entscheider:** ____________________
**Review durch:** ____________________

---

## Gewaehler Ansatz

- [ ] **Allowlist** (`tools.core`) — nur explizit genannte Tools erlaubt
- [ ] **Blocklist** (`tools.exclude`) — alle Tools erlaubt ausser genannten

---

## Begruendung

*(Pflichtfeld fuer DORA Art. 9 — Entscheidung muss dokumentiert sein)*

```
Unser Anwendungsfall:


Warum dieser Ansatz fuer unser Risikoprofil ausreicht:


Kompensationskontrollen (falls Blocklist gewaehlt):

```

---

## Aktuelle Konfiguration (`settings.json`)

```json
(Inhalt hier eintragen oder Datei referenzieren)
```

---

## Erlaubte Tools (Allowlist) / Gesperrte Tools (Blocklist)

| Tool | Erlaubt/Gesperrt | Begruendung |
|---|---|---|
| | | |

---

## Risikobewertung

| Risiko | Wahrscheinlichkeit | Impact | Massnahme |
|---|---|---|---|
| Agent ruft unerlaubtes Tool auf | | | Allowlist / Negativ-Test in Pipeline |
| Prompt Injection umgeht Tool-Kontrolle | | | Injection-Tests in Pipeline, Sandbox Ebene 1 |
| Update aendert Tool-Verhalten | | | Behavioral Regression Tests |

---

## Naechstes Review-Datum

____________________

*(Empfehlung: mindestens halbjährlich oder nach jeder Gemini CLI Version-Aenderung)*
