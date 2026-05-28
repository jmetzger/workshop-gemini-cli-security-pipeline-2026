# Uebung 2: Regression Detection mit Gemini-Judge

**Hermes-Phase:** Independent Verification — unabhaengige Bewertung durch separaten Agenten

## Lernziel

Du verstehst den Unterschied zwischen kosmetischen und verhaltens-aendernden Skill-Modifikationen.
Du lernst, wie ein LLM-Judge mit Rubrik-basierter Bewertung Regressionen erkennt.

## Hintergrund

```
Hermes 2.0 Phase 2: INDEPENDENT VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Veraenderter Skill → Gemini fuehrt Szenarien aus → Gemini-Judge bewertet
                                                     Baseline vs. neu
                                                     → PASS / FAIL
```

Hermes-Grundsatz: "Kein Agent prueft seine eigene Arbeit."
→ Der Judge ist ein SEPARATER Gemini-Aufruf mit frischem Kontext.

## Die zwei Skill-Varianten

### Variante A: Kosmetische Aenderung (`workshop-training-kosmetisch.md`)

**Was wurde geaendert:**
- Tabellenformatierung angepasst (mehr Leerzeichen fuer Ausrichtung)
- Abschnitt "Verifizierung vor Commit" nach vorne verschoben
- SVG-Sektion stark gekuerzt (gleiche Kernaussage, weniger Detail)
- Einleitungssatz leicht umformuliert

**Erwartetes Judge-Ergebnis:** PASS — gleiches Verhalten, andere Praesentation

### Variante B: Behavior-Aenderung (`workshop-training-behavioral.md`)

**Was wurde geaendert (3 gezielte Regressionen):**

| Regression | Original | Geaendert zu |
|------------|----------|--------------|
| Namespace-Konvention | `<prefix>-<dein-name>` Format vorgeschrieben | Fester Name erlaubt, Namespace IM Manifest OK |
| Dateiendung | `.yml` (explizit, nicht `.yaml`) | `.yaml` |
| TEST-PFLICHT | Eigener Abschnitt, als Pflicht markiert | Abschnitt entfernt |

**Erwartetes Judge-Ergebnis:** FAIL — diese 3 Aenderungen fuehren zu falschem Verhalten auf dem Cluster

## Vorbereitung

```
# Baseline aus Uebung 1 muss vorhanden sein!
ls ../uebung-01-baseline/baseline/

export GEMINI_API_KEY=dein-api-key
```

## Schritt 1: Diff untersuchen

Bevor du den Judge laeuft — untersuche selbst die Unterschiede:

```
diff ../skill-variants/workshop-training-kosmetisch.md \
     ../../.claude/skills/workshop-training/SKILL.md | head -60
```

```
diff ../skill-variants/workshop-training-behavioral.md \
     ../../.claude/skills/workshop-training/SKILL.md
```

**Aufgabe:** Identifiziere die 3 Regressionen in der behavioral Variante, BEVOR du den Judge ausfuehrst.

## Schritt 2: Kosmetische Aenderung testen

```
python scripts/02_run_judge.py kosmetisch
```

**Erwartung:** PASS (Score 8-10/10)

## Schritt 3: Behavioral-Aenderung testen

```
python scripts/02_run_judge.py behavioral
```

**Erwartung:** FAIL (Score unter 8/10)

Lies die Ausgabe: Welche Regressionen hat der Judge erkannt?
Hat er alle 3 gefunden?

## Schritt 4: Beide vergleichen

```
python scripts/02_run_judge.py beide
```

## Diskussionsfragen

1. **Warum benoetigen wir Szenarien statt direktem Diff?**
   Ein LLM kann einen Text umformulieren und trotzdem die gleiche Semantik behalten.
   Ein String-Diff wuerde "FAIL" sagen, obwohl das Verhalten identisch ist.

2. **Warum ist Score 8/10 als Threshold sinnvoll (nicht 10/10)?**
   Kleine Formulierungsunterschiede, zusaetzliche Beispiele etc. sind OK.
   Wir wollen VERHALTEN pruefen, nicht exakte Reproduzierbarkeit.

3. **Was passiert wenn der Judge falsch liegt?**
   → Hermes nutzt mehrere Szenarien (wir haben 4) und braucht alle im PASS-Bereich.
   → False Positives (FAIL obwohl OK) sind besser als False Negatives (PASS obwohl kaputt).

## Erwartetes Ergebnis

```
ZUSAMMENFASSUNG:
  Kosmetische Aenderung:          PASS (8.5/10)
  Behavior-Aenderung (REGRESSION): FAIL (4.2/10)
```

---
Weiter mit: **Uebung 3 — CI/CD Pipeline**
