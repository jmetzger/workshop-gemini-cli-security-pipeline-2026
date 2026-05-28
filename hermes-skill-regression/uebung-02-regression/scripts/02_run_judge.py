#!/usr/bin/env python3
"""
Uebung 2: Regression Detection mit Gemini als LLM-Judge (Schritt 2 von Hermes 2.0)

Vergleicht den Output eines veraenderten Skills mit der Baseline.
Gemini bewertet nach einer Rubrik ob eine Regression vorliegt.
"""

import json
import os
import sys
from pathlib import Path

import yaml

try:
    import google.generativeai as genai
except ImportError:
    print("FEHLER: google-generativeai nicht installiert.")
    print("Ausfuehren: pip install google-generativeai")
    sys.exit(1)


BASELINE_DIR = Path(__file__).parent.parent.parent / "uebung-01-baseline/baseline"
SCENARIOS_PATH = Path(__file__).parent.parent.parent / "uebung-01-baseline/tests/scenarios.yaml"
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.0-flash")

JUDGE_RUBRIK = """Du bist ein unabhaengiger Qualitaetsprueferr fuer KI-Skill-Verhalten.
Vergleiche den NEUEN OUTPUT mit dem BASELINE OUTPUT eines Kubernetes-Workshop-Skills.

BASELINE OUTPUT (Referenz - so soll es sein):
{baseline}

NEUER OUTPUT (nach Skill-Aenderung):
{neuer_output}

TEST-SZENARIO: {szenario_name}

Bewerte nach dieser Rubrik:

1. KERNFUNKTIONALITAET (0-3 Punkte)
   3: Alle wichtigen Konventionen korrekt erklaert
   2: Die meisten Konventionen vorhanden, kleinere Luecken
   1: Wichtige Konventionen fehlen oder sind unvollstaendig
   0: Kernfunktionalitaet fehlt oder ist falsch

2. NAMESPACE-KONVENTION (0-3 Punkte)
   3: Format <prefix>-<dein-name> klar beschrieben, Namespace NICHT im Manifest
   2: Einer der beiden Aspekte korrekt
   1: Unklare oder widersprüchliche Angaben
   0: Konvention falsch oder nicht erwaehnt

3. OUTPUT-STRUKTUR (0-2 Punkte)
   2: Schritt-fuer-Schritt Struktur, Aufraeumen-Sektion, korrekte Dateiendungen
   1: Struktur vorhanden aber unvollstaendig
   0: Keine erkennbare Struktur

4. KEINE FALSCHEN INFORMATIONEN (0-2 Punkte)
   2: Alles korrekt, keine widerspruchlichen oder falschen Aussagen
   1: Kleinere Ungenauigkeiten
   0: Falsche Informationen die Teilnehmer in die Irre fuehren wuerden

Antworte NUR im folgenden JSON-Format (kein anderer Text):
{{
  "score": <Gesamtpunktzahl 0-10>,
  "result": "PASS",
  "details": {{
    "kernfunktionalitaet": {{"score": <0-3>, "comment": "<kurze Begruendung>"}},
    "namespace_konvention": {{"score": <0-3>, "comment": "<kurze Begruendung>"}},
    "output_struktur": {{"score": <0-2>, "comment": "<kurze Begruendung>"}},
    "keine_falschen_infos": {{"score": <0-2>, "comment": "<kurze Begruendung>"}}
  }},
  "regressionen": ["<Liste der gefundenen Regressionen, leer wenn keine>"],
  "zusammenfassung": "<1-2 Saetze Gesamtbewertung>"
}}

Ersetze "PASS" durch "FAIL" wenn score < 8. Threshold: 8/10 = PASS."""


def load_scenarios(path: Path) -> list[dict]:
    with open(path, encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data["scenarios"]


def load_baseline(scenario_id: str) -> str | None:
    baseline_file = BASELINE_DIR / f"{scenario_id}.txt"
    if not baseline_file.exists():
        return None
    return baseline_file.read_text(encoding="utf-8")


def run_scenario_with_skill(skill_content: str, scenario: dict, model) -> str:
    prompt = f"""Du arbeitest mit dem folgenden Skill-Kontext:

---SKILL START---
{skill_content}
---SKILL ENDE---

AUFGABE: {scenario['prompt']}"""

    response = model.generate_content(prompt)
    return response.text


def judge_output(baseline: str, neuer_output: str, szenario_name: str, model) -> dict:
    judge_prompt = JUDGE_RUBRIK.format(
        baseline=baseline[:3000],
        neuer_output=neuer_output[:3000],
        szenario_name=szenario_name,
    )
    response = model.generate_content(judge_prompt)

    text = response.text.strip()
    if text.startswith("```"):
        text = text.split("```")[1]
        if text.startswith("json"):
            text = text[4:]
    text = text.strip().rstrip("```").strip()

    return json.loads(text)


def run_evaluation(skill_path: Path, label: str, model, scenarios: list[dict]) -> dict:
    skill_content = skill_path.read_text(encoding="utf-8")
    print(f"\n{'='*60}")
    print(f"Evaluiere: {label}")
    print(f"Skill: {skill_path.name}")
    print('='*60)

    ergebnisse = []
    for scenario in scenarios:
        sid = scenario["id"]
        baseline = load_baseline(sid)
        if baseline is None:
            print(f"  WARNUNG: Keine Baseline fuer {sid} - Uebung 1 zuerst ausfuehren!")
            continue

        print(f"\nSzenario: {sid}")
        neuer_output = run_scenario_with_skill(skill_content, scenario, model)
        urteil = judge_output(baseline, neuer_output, scenario["name"], model)

        symbol = "PASS" if urteil["result"] == "PASS" else "FAIL"
        print(f"  Ergebnis: {symbol} ({urteil['score']}/10)")
        print(f"  Zusammenfassung: {urteil['zusammenfassung']}")
        if urteil.get("regressionen"):
            print(f"  Regressionen:")
            for r in urteil["regressionen"]:
                print(f"    - {r}")

        ergebnisse.append({"szenario": sid, "urteil": urteil})

    gesamt_score = sum(e["urteil"]["score"] for e in ergebnisse) / len(ergebnisse) if ergebnisse else 0
    gesamt_result = "PASS" if all(e["urteil"]["result"] == "PASS" for e in ergebnisse) else "FAIL"

    print(f"\n{'='*60}")
    print(f"GESAMTERGEBNIS {label}: {gesamt_result} (Durchschnitt: {gesamt_score:.1f}/10)")
    print('='*60)

    return {"label": label, "result": gesamt_result, "avg_score": gesamt_score, "details": ergebnisse}


def main():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("FEHLER: GEMINI_API_KEY nicht gesetzt.")
        sys.exit(1)

    variant = sys.argv[1] if len(sys.argv) > 1 else "beide"

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel(GEMINI_MODEL)
    scenarios = load_scenarios(SCENARIOS_PATH)

    base_dir = Path(__file__).parent.parent / "skill-variants"

    if not BASELINE_DIR.exists() or not (BASELINE_DIR / "baseline_meta.json").exists():
        print("FEHLER: Keine Baseline gefunden.")
        print("Erst Uebung 1 ausfuehren: python uebung-01-baseline/scripts/01_create_baseline.py")
        sys.exit(1)

    ergebnisse = {}

    if variant in ("kosmetisch", "beide"):
        pfad = base_dir / "workshop-training-kosmetisch.md"
        ergebnisse["kosmetisch"] = run_evaluation(pfad, "Kosmetische Aenderung", model, scenarios)

    if variant in ("behavioral", "beide"):
        pfad = base_dir / "workshop-training-behavioral.md"
        ergebnisse["behavioral"] = run_evaluation(pfad, "Behavior-Aenderung (REGRESSION)", model, scenarios)

    print("\n\nZUSAMMENFASSUNG:")
    print("-" * 40)
    for key, r in ergebnisse.items():
        symbol = "PASS" if r["result"] == "PASS" else "FAIL"
        print(f"  {r['label']}: {symbol} ({r['avg_score']:.1f}/10)")

    print("\nLEHRPUNKT:")
    print("  Die kosmetische Aenderung sollte PASS zeigen — gleiches Verhalten, andere Worte.")
    print("  Die behavioral-Aenderung sollte FAIL zeigen — Namespace-Konvention falsch,")
    print("  TEST-PFLICHT entfernt, Dateiendung .yaml statt .yml.")


if __name__ == "__main__":
    main()
