# Uebung 1: Golden Baseline erstellen

**Hermes-Phase:** Reflective Phase — Verhalten festhalten bevor Aenderungen gemacht werden

## Lernziel

Du verstehst, wie Hermes eine unveraenderliche Baseline als Vergleichsmassstab erstellt.
Du lernst, Testszenarien fuer Skills zu definieren und die Outputs automatisiert zu speichern.

## Hintergrund

```
Hermes 2.0 Phase 1: REFLECTIVE PHASE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Skill (vorher) → Testszenarien → Gemini fuehrt aus → Outputs speichern
                                                       = Golden Baseline
```

Bevor wir einen Skill aendern, muessen wir wissen wie er sich JETZT verhaelt.
Diese Baseline ist danach unveraenderlich — sie ist unser "So soll es sein".

## Vorbereitung

```
cd uebung-01-baseline
pip install google-generativeai pyyaml
export GEMINI_API_KEY=dein-api-key
```

## Schritt 1: Testszenarien verstehen

Oeffne `tests/scenarios.yaml` und lies die 4 Szenarien.

Jedes Szenario hat:
- `id` — eindeutiger Name
- `prompt` — was wird vom Skill verlangt?
- `erwartete_merkmale` — was MUSS in einer korrekten Antwort stehen?

**Aufgabe:** Ueberlege fuer Szenario S01, welche Aenderung am Skill diese Merkmale verletzen wuerde.

## Schritt 2: Baseline erstellen

```
python scripts/01_create_baseline.py
```

**Was passiert:**
1. Skill-Datei wird geladen (`~/.claude/skills/workshop-training/SKILL.md`)
2. Skill-Fingerprint (SHA256) wird berechnet
3. Fuer jedes Szenario: Gemini-Anfrage mit Skill als Kontext
4. Outputs werden in `baseline/S01-*.txt` gespeichert
5. `baseline/baseline_meta.json` dokumentiert alles

## Schritt 3: Baseline untersuchen

```
ls baseline/
cat baseline/S01-resourcequota.txt
cat baseline/baseline_meta.json
```

**Aufgaben:**
- Pruefe ob S01 alle `erwarteten_merkmale` aus scenarios.yaml erwaehnt
- Notiere dir 3 Schluesselphrassen aus der Antwort

## Diskussion

- Warum reicht ein SHA256-Vergleich der Outputs NICHT aus?
- Warum brauchen wir einen LLM-Judge statt exakter String-Vergleich?
- Was ist der Unterschied zwischen struktureller und semantischer Aenderung?

## Erwartetes Ergebnis

```
baseline/
  S01-resourcequota.txt
  S02-namespace-konvention.txt
  S03-test-pflicht.txt
  S04-dateikonventionen.txt
  baseline_meta.json
```

---
Weiter mit: **Uebung 2 — Regression erkennen**
