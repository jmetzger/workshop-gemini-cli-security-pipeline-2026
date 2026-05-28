# Skill Regression Testing — Reverse Engineering Hermes 2.0

Drei aufbauende Uebungen, die zeigen wie Hermes 2.0 automatisch prueft,
ob Skills nach Aenderungen noch gleich funktionieren.

## Das Problem

```
Skill wird verbessert/veraendert
           │
           ▼
    Funktioniert er noch
    gleich wie vorher?
           │
    ┌──────┴──────┐
    │             │
   Ja            Nein
 (PASS)         (FAIL = Regression)
```

Ohne Mechanismus: niemand weiss es bis ein Teilnehmer einen Fehler meldet.
Mit Hermes-Mechanismus: automatisch erkannt, PR wird geblockt.

## Hermes 2.0 Architektur (vereinfacht)

```
Phase 1: REFLECTIVE PHASE
  → Baseline erstellen (Golden Snapshot)
  → Testszenarien definieren

Phase 2: EXECUTION IN SANDBOX
  → Geaenderter Skill wird mit Gemini ausgefuehrt
  → Alle Szenarien werden durchgespielt

Phase 3: INDEPENDENT VERIFICATION
  → Separater Gemini-Judge (kein Self-Review!)
  → Rubrik-basierte Bewertung (0-10 Punkte)
  → CONSTRAINT GATE: Score < 8 → FAIL → Pipeline bricht ab
```

## Die 3 Uebungen

| Uebung | Phase | Was du lernst |
|--------|-------|---------------|
| [Uebung 1: Baseline](uebung-01-baseline/README.md) | Reflective Phase | Testszenarien definieren, Golden Snapshot erstellen |
| [Uebung 2: Regression Detection](uebung-02-regression/README.md) | Independent Verification | Kosmetisch vs. behavioral, LLM-as-Judge |
| [Uebung 3: CI/CD Pipeline](uebung-03-pipeline/README.md) | Vollstaendige Pipeline | Alle 3 Phasen automatisiert in GitHub Actions |

## Schnellstart

```
pip install -r requirements.txt
export GEMINI_API_KEY=dein-api-key

# Uebung 1
python uebung-01-baseline/scripts/01_create_baseline.py

# Uebung 2
python uebung-02-regression/scripts/02_run_judge.py beide

# Uebung 3
export CHANGED_SKILLS="uebung-02-regression/skill-variants/workshop-training-behavioral.md"
python uebung-03-pipeline/scripts/03_run_scenarios.py
python uebung-03-pipeline/scripts/03_judge.py
```

## Warum Gemini als Judge?

- Einheitliches Modell (Gemini fuer Ausfuehren UND Bewerten)
- Funktioniert in Gemini-only Unternehmensumgebungen
- Kein Anthropic/OpenAI API-Key benoetigt
- `GEMINI_MODEL` Umgebungsvariable zum Wechseln des Modells

## Projektstruktur

```
.
├── uebung-01-baseline/
│   ├── README.md              # Uebungsanleitung
│   ├── tests/scenarios.yaml   # 4 Test-Szenarien
│   ├── scripts/01_create_baseline.py
│   └── baseline/              # (wird beim Ausfuehren erstellt)
│
├── uebung-02-regression/
│   ├── README.md
│   ├── skill-variants/
│   │   ├── workshop-training-kosmetisch.md   # → PASS erwartet
│   │   └── workshop-training-behavioral.md   # → FAIL erwartet (3 Regressionen)
│   └── scripts/02_run_judge.py
│
├── uebung-03-pipeline/
│   ├── README.md
│   └── scripts/
│       ├── 03_run_scenarios.py   # Pipeline Phase 2
│       └── 03_judge.py           # Pipeline Phase 3
│
├── .github/workflows/
│   └── skill-regression-test.yml  # Vollstaendige CI/CD Pipeline
│
└── requirements.txt
```

## Die 3 Regressionen in der behavioral Variante

Als Lernkontrolle: kannst du diese vor dem Judge-Lauf selbst identifizieren?

| # | Bereich | Original | Fehlerhafte Variante |
|---|---------|----------|---------------------|
| 1 | Namespace-Format | `<prefix>-<dein-name>` Pflicht | Fester Name erlaubt |
| 2 | Namespace-Ort | NICHT im Manifest | Im Manifest erlaubt |
| 3 | Dateiendung | `.yml` | `.yaml` |
| 4 | TEST-PFLICHT | Eigener Abschnitt, als Pflicht | Abschnitt entfernt |
