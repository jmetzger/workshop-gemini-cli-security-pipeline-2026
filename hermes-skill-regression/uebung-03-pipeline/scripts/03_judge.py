#!/usr/bin/env python3
"""
Uebung 3 / Pipeline Phase 3: Gemini-Judge

Wird von der GitHub Actions Pipeline aufgerufen.
Vergleicht neue Outputs mit Baseline und gibt JSON-Report aus.
Exit-Code 0 = PASS, Exit-Code 1 = FAIL (Regression erkannt).
"""

import json
import os
import sys
from pathlib import Path

try:
    import google.generativeai as genai
except ImportError:
    print("FEHLER: google-generativeai nicht installiert.", file=sys.stderr)
    sys.exit(1)


BASELINE_DIR = Path("baseline")
OUTPUT_DIR = Path("outputs")
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.0-flash")
PASS_THRESHOLD = 8

JUDGE_PROMPT = """Du bist ein unabhaengiger Qualitaetspruefer fuer KI-Skill-Verhalten.
Vergleiche BASELINE und NEUEN OUTPUT eines Kubernetes-Workshop-Skills.

BASELINE:
{baseline}

NEUER OUTPUT:
{neuer_output}

SZENARIO: {szenario_id}

Rubrik (Gesamt 10 Punkte):
- Kernfunktionalitaet (0-3): Alle wichtigen Konventionen korrekt?
- Namespace-Konvention (0-3): <prefix>-<dein-name>, NICHT im Manifest?
- Output-Struktur (0-2): Schritt-fuer-Schritt, Aufraeumen, .yml?
- Keine Fehler (0-2): Keine falschen oder widerspruchlichen Informationen?

Antworte NUR als JSON:
{{
  "score": <0-10>,
  "result": "PASS oder FAIL",
  "details": {{
    "kernfunktionalitaet": {{"score": <0-3>, "comment": ""}},
    "namespace_konvention": {{"score": <0-3>, "comment": ""}},
    "output_struktur": {{"score": <0-2>, "comment": ""}},
    "keine_fehler": {{"score": <0-2>, "comment": ""}}
  }},
  "regressionen": [],
  "zusammenfassung": ""
}}

PASS wenn score >= {threshold}. FAIL wenn score < {threshold}."""


def parse_judge_json(text: str) -> dict:
    text = text.strip()
    if "```" in text:
        parts = text.split("```")
        for part in parts:
            if "{" in part:
                text = part.lstrip("json").strip()
                break
    return json.loads(text)


def judge(baseline: str, neuer_output: str, szenario_id: str, model) -> dict:
    prompt = JUDGE_PROMPT.format(
        baseline=baseline[:2500],
        neuer_output=neuer_output[:2500],
        szenario_id=szenario_id,
        threshold=PASS_THRESHOLD,
    )
    response = model.generate_content(prompt)
    return parse_judge_json(response.text)


def main():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print('{"error": "GEMINI_API_KEY nicht gesetzt"}')
        sys.exit(1)

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel(GEMINI_MODEL)

    output_files = list(OUTPUT_DIR.glob("*.txt"))
    if not output_files:
        print('{"error": "Keine Output-Dateien in outputs/ gefunden"}')
        sys.exit(1)

    ergebnisse = []
    for output_file in output_files:
        parts = output_file.stem.split("__", 1)
        if len(parts) != 2:
            continue
        _, szenario_id = parts

        baseline_file = BASELINE_DIR / f"{szenario_id}.txt"
        if not baseline_file.exists():
            continue

        baseline = baseline_file.read_text(encoding="utf-8")
        neuer_output = output_file.read_text(encoding="utf-8")

        urteil = judge(baseline, neuer_output, szenario_id, model)
        ergebnisse.append({"szenario": szenario_id, "urteil": urteil})

    if not ergebnisse:
        print('{"error": "Keine Baseline-Matches gefunden"}')
        sys.exit(1)

    avg_score = sum(e["urteil"]["score"] for e in ergebnisse) / len(ergebnisse)
    overall = "PASS" if all(e["urteil"]["result"] == "PASS" for e in ergebnisse) else "FAIL"

    report = {
        "overall_result": overall,
        "avg_score": round(avg_score, 2),
        "pass_threshold": PASS_THRESHOLD,
        "szenarien_geprueft": len(ergebnisse),
        "details": ergebnisse,
    }

    print(json.dumps(report, indent=2, ensure_ascii=False))
    sys.exit(0 if overall == "PASS" else 1)


if __name__ == "__main__":
    main()
