# Uebung 3: CI/CD Pipeline mit allen 3 Hermes-Phasen

**Hermes-Phase:** Vollstaendige automatisierte Pipeline — wie Hermes 2.0 es macht

## Lernziel

Du verstehst, wie die 3 Phasen von Hermes als automatisierte CI/CD-Pipeline zusammenarbeiten.
Du kannst diese Pipeline auf deine eigenen Skills anwenden.

## Architektur: Hermes 2.0 vollstaendig implementiert

```
Git Push (Skill-Aenderung)
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  PHASE 1: Baseline laden / erstellen                │
│  • Prueft ob baseline/baseline_meta.json existiert  │
│  • Falls nein: erstellt neue Baseline via Gemini    │
│  • Speichert als GitHub Actions Artefakt (90 Tage) │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│  PHASE 2: Skill ausfuehren (in Sandbox)             │
│  • Ermittelt geaenderte Skill-Dateien (git diff)    │
│  • Fuehrt alle 4 Szenarien via Gemini aus           │
│  • Speichert neue Outputs als Artefakt              │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│  PHASE 3: Gemini-Judge (Independent Verification)   │
│  • Laedt Baseline + neue Outputs                    │
│  • Gemini bewertet nach Rubrik (10 Punkte)         │
│  • CONSTRAINT GATE: Score >= 8 = PASS, < 8 = FAIL  │
│  • FAIL → Pipeline bricht ab, PR wird geblockt      │
└─────────────────────────────────────────────────────┘
```

## Sicherheitsueberleguung: Gemini-only Umgebung

In Firmen die nur Gemini erlauben (kein OpenAI, kein Claude API):

```
GEMINI_API_KEY    → Wird als GitHub/GitLab Secret gespeichert
                    Kein Anthropic-Key notwendig
                    Kein OpenAI-Key notwendig

Modell-Wahl:
  GEMINI_MODEL=gemini-2.0-flash    → Schnell, kostenguenstig (Judge + Run)
  GEMINI_MODEL=gemini-1.5-pro      → Genauer fuer komplexe Skills
```

## Vorbereitung

### Option A: GitHub Actions (empfohlen)

1. Repository einrichten:
```
git init
git add .
git commit -m "Initial skill regression testing setup"
gh repo create mein-skill-test --private
git remote add origin https://github.com/USER/mein-skill-test.git
git push -u origin main
```

2. Secret setzen:
```
gh secret set GEMINI_API_KEY --body "dein-api-key"
```

3. Pipeline testen (manuell ausloesen):
```
gh workflow run skill-regression-test.yml \
  --field skill_path=skills/workshop-training/SKILL.md
```

4. Status beobachten:
```
gh run watch
```

### Option B: Lokal ausfuehren (ohne GitHub Actions)

```
export GEMINI_API_KEY=dein-api-key
export CHANGED_SKILLS="skills/workshop-training/SKILL.md"

# Phase 1: Baseline (falls noch nicht vorhanden)
python uebung-01-baseline/scripts/01_create_baseline.py

# Phase 2: Szenarien ausfuehren
python uebung-03-pipeline/scripts/03_run_scenarios.py

# Phase 3: Judge
python uebung-03-pipeline/scripts/03_judge.py
```

## Schritt 1: Behavioral-Variante in Pipeline testen

Kopiere die fehlerhafte Variante als zu testenden Skill:

```
cp uebung-02-regression/skill-variants/workshop-training-behavioral.md \
   skills/workshop-training/SKILL.md
git add skills/workshop-training/SKILL.md
git commit -m "TEST: fehlerhafte Skill-Variante (sollte FAIL zeigen)"
git push
```

**Erwartung:** Pipeline Phase 3 bricht ab. PR kann nicht gemergt werden.

## Schritt 2: Original wiederherstellen

```
cp ~/.claude/skills/workshop-training/SKILL.md skills/workshop-training/SKILL.md
git add skills/workshop-training/SKILL.md
git commit -m "Restore: korrekter Skill (sollte PASS zeigen)"
git push
```

**Erwartung:** Alle 3 Phasen erfolgreich. Pipeline ist gruen.

## Schritt 3: Pipeline-Output verstehen

```
gh run view --log | grep -A 5 "REGRESSION\|PASS\|FAIL"
```

Oder im GitHub Actions Tab: Actions → skill-regression-test → Phase 3

## Diskussion: Firmen mit Einschraenkungen

**Szenario: Nur Gemini erlaubt (kein externes LLM)**

```yaml
# In der Pipeline: GEMINI_API_KEY als einziges Secret
# Kein Anthropic/OpenAI Key benoetigt
# Vertex AI Alternative:
env:
  GOOGLE_CLOUD_PROJECT: mein-projekt
  GOOGLE_APPLICATION_CREDENTIALS: /path/to/sa.json
  GEMINI_MODEL: gemini-2.0-flash
```

**Szenario: Kein externes API erlaubt (Air-Gap)**

→ Lokale Alternative: Ollama mit llama3 als Judge
→ Qualitaet geringer, aber Prinzip identisch
→ Skripte sind modular: nur `GEMINI_MODEL` und Bibliothek wechseln

## Erwartetes Pipeline-Ergebnis

```
Phase 1 - Baseline laden:   PASS (gruener Haken)
Phase 2 - Skill ausfuehren: PASS (gruener Haken)
Phase 3 - Judge:            FAIL (roter X) bei behavioral-Variante
                            PASS (gruener Haken) bei Original

Constraint Gate Output:
  REGRESSION ERKANNT!
  Szenario S02-namespace-konvention: FAIL (3/10)
    - Namespace-Format fehlt (<prefix>-<dein-name> nicht erwaehnt)
    - Namespace im Manifest wird als RICHTIG dargestellt (war FALSCH)
  Szenario S03-test-pflicht: FAIL (5/10)
    - TEST-PFLICHT Anforderung nicht mehr vorhanden
```

---
## Gesamtrueckblick: Was wir von Hermes 2.0 uebernommen haben

| Hermes-Mechanismus | Unsere Implementierung |
|-------------------|----------------------|
| Reflective Phase | Baseline-Skript (Uebung 1) |
| GEPA Optimizer | Szenario-Runner via Gemini (Phase 2) |
| Independent Verifier | Separater Judge-Aufruf (Phase 3) |
| Constraint Gate | Exit-Code 1 blockiert Pipeline |
| Curation System | (Erweiterung: manuelles Review des Judge-Reports) |
