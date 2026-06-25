# DORA und LLM Injection Testing — Die ehrliche Einordnung

## Warum LLM Injection Tests fuer DORA relevant sind

DORA erwaehnt "LLM Injection" mit keinem Wort. Die Verbindung laeuft ueber
allgemeine ICT-Risiko-Pflichten.

```
DORA Art. 8: Du musst ICT-Risiken identifizieren
        |
        v
LLM-Agent ist ein ICT-System → gehoert ins Risikoregister
        |
        v
DORA Art. 9: Fuer identifizierte Risiken musst du Controls implementieren
        |
        v
Prompt Injection ist das Top-Risiko eines LLM-Agenten (OWASP LLM01)
        |
        v
DORA Art. 24: Controls muessen getestet und die Tests dokumentiert sein
        |
        v
LLM Injection Testing ist die Testmethode fuer dieses Control
```

---

## Das fundamentale Problem: Tests sind unvollstaendig per Definition

Klassischer Security-Test vs. LLM-Test:

```
Klassischer Unit-Test:
  Input A → Funktion → Output B   (deterministisch, reproduzierbar)
  PASS bedeutet: wird immer so funktionieren

LLM Injection-Test:
  Input A → LLM → Output B?       (probabilistisch, nicht reproduzierbar)
  PASS bedeutet: hat DIESMAL so funktioniert
```

**Ein PASS beweist nichts ueber den naechsten Aufruf.**

### Was die Tests beweisen

- Diese **spezifischen** Angriffsmuster haben bei **diesem** Modell zum **Zeitpunkt X** keine verbotene Aktion ausgeloest
- Die **Sandbox-Controls** (`--network none`, `--read-only`) funktionieren technisch
- Es gibt eine **dokumentierte Baseline** — Abweichungen fallen auf

### Was die Tests nicht beweisen

- Dass eine leicht abgewandelte Formulierung des gleichen Angriffs auch scheitert
- Dass das Verhalten nach einem **Model-Update** noch gleich ist
- Dass **indirekte Injection** aus beliebigem externen Content abgewehrt wird
- Dass **Multi-Turn-Angriffe** ueber mehrere Nachrichten nicht funktionieren
- Dass das System gegen Angriffe resistent ist die noch niemand kennt

---

## Was die Tests trotzdem wert sind

| Nutzen | Erklaerung |
|--------|------------|
| **Regression-Baseline** | Wenn ein Model-Update das Verhalten aendert, schlaegt der Test an |
| **Strukturierte Taxonomie** | OWASP LLM01-Kategorien erzwingen systematische Abdeckung statt ad-hoc |
| **Varianten-Generierung** | `promptfoo redteam run` erzeugt automatisch neue Angriffsvarianten |
| **Dokumentierter Scope** | Fuer Pruefer: was getestet wurde, wann, mit welchem Ergebnis |

---

## Die ehrliche DORA-Einordnung

DORA Art. 24 verlangt **"angemessenes Testen"** — nicht den Beweis vollstaendiger
Sicherheit. Das ist bewusst so formuliert, weil vollstaendiger Beweis bei
probabilistischen Systemen nicht moeglich ist.

### Was DORA akzeptiert

```
"Wir haben zum Zeitpunkt X folgende Angriffskategorien nach OWASP LLM Top 10
 getestet, folgende Ergebnisse dokumentiert, und fuehren das quartalsweise durch."
```

### Was DORA nicht akzeptiert

```
"Wir haben mal manuell ein paar Prompts ausprobiert."
```

Der Unterschied liegt nicht im technischen Ergebnis — sondern in
**Systematik**, **Dokumentation** und **Wiederholung**.

---

## Mapping: DORA-Artikel → LLM Injection Testing

| DORA-Artikel | Anforderung | Was Injection-Testing liefert |
|-------------|-------------|-------------------------------|
| Art. 8 | Risiken identifizieren | OWASP LLM01 als dokumentiertes Risiko |
| Art. 9 | Controls implementieren | Defense-in-Depth (System Prompt + Sandbox) |
| Art. 10 | Angriffe erkennen | Monitoring von Agent-Outputs |
| Art. 24 | Controls testen und nachweisen | `promptfoo-report.json` als Audit-Evidence |
| Art. 12 | Aufzeichnungen aufbewahren | Archivierte Testergebnisse (Pflicht: 5 Jahre) |

**Achtung Aufbewahrung:** DORA Art. 12 verlangt 5 Jahre — nicht 1 Jahr.
`expire_in: 1 year` in GitLab reicht nicht. Ergebnisse muessen in ein
externes Archiv exportiert werden.

---

## Fuer Finanzinstitute: Warum es besonders brennt

Wenn ein LLM-Agent im Finanzsektor durch Injection manipuliert wird:

- **Falsche Kreditentscheidungen** durch manipulierten Output
- **Secrets aus CI/CD-Pipeline exfiltriert** (Bankzugaenge, Zertifikate)
- **Regulatorische Berichte verfaelscht** durch indirekten Injection-Angriff

Das sind keine theoretischen Szenarien — das sind **meldepflichtige ICT-Vorfaelle
unter DORA Art. 17** mit Meldefristen:

| Pflicht | Frist |
|---------|-------|
| Erstmeldung an Aufsicht | 4 Stunden nach Klassifizierung |
| Zwischenbericht | 72 Stunden |
| Abschlussbericht | 1 Monat |

---

## Fazit

LLM Injection Tests sind notwendig — aber nicht hinreichend. Der Wert liegt in:

1. **Systematischer Abdeckung** bekannter Kategorien (OWASP LLM Top 10)
2. **Nachweisbarer Wiederholung** ueber Zeit (CI/CD, quartalsweise)
3. **Fruehwarnung** bei Verhaltensaenderungen durch Model-Updates
4. **Dokumentiertem Scope** der dem Pruefer zeigt dass es ernst genommen wird

Das Restrisiko muss formal anerkannt werden — das ist keine Schwaeche,
sondern Teil eines ehrlichen Risikomanagements das DORA fordert.
