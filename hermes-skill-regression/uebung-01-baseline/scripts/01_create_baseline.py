#!/usr/bin/env python3
"""
Uebung 1: Golden Baseline erstellen (Schritt 1 von Hermes 2.0)

Laedt den Skill, fuehrt alle Test-Szenarien via Gemini aus
und speichert die Ergebnisse als unveraenderliche Baseline.
"""

import json
import os
import sys
import hashlib
from datetime import datetime
from pathlib import Path

import yaml

try:
    import google.generativeai as genai
except ImportError:
    print("FEHLER: google-generativeai nicht installiert.")
    print("Ausfuehren: pip install google-generativeai")
    sys.exit(1)


SKILL_PATH = Path(__file__).parent.parent.parent.parent / ".claude/skills/workshop-training/SKILL.md"
SCENARIOS_PATH = Path(__file__).parent.parent / "tests/scenarios.yaml"
BASELINE_DIR = Path(__file__).parent.parent / "baseline"

GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.0-flash")


def load_skill(path: Path) -> str:
    if not path.exists():
        print(f"FEHLER: Skill nicht gefunden: {path}")
        sys.exit(1)
    return path.read_text(encoding="utf-8")


def load_scenarios(path: Path) -> list[dict]:
    with open(path, encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data["scenarios"]


def run_scenario_with_gemini(skill_content: str, scenario: dict, model) -> str:
    """Fuehrt ein Test-Szenario mit dem Skill als Kontext aus."""
    prompt = f"""Du arbeitest mit dem folgenden Skill-Kontext:

---SKILL START---
{skill_content}
---SKILL ENDE---

AUFGABE: {scenario['prompt']}"""

    response = model.generate_content(prompt)
    return response.text


def compute_fingerprint(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()[:12]


def main():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("FEHLER: GEMINI_API_KEY Umgebungsvariable nicht gesetzt.")
        print("Ausfuehren: export GEMINI_API_KEY=dein-api-key")
        sys.exit(1)

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel(GEMINI_MODEL)

    print(f"Lade Skill von: {SKILL_PATH}")
    skill_content = load_skill(SKILL_PATH)
    skill_fingerprint = compute_fingerprint(skill_content)
    print(f"Skill-Fingerprint: {skill_fingerprint}")

    print(f"Lade Szenarien von: {SCENARIOS_PATH}")
    scenarios = load_scenarios(SCENARIOS_PATH)
    print(f"{len(scenarios)} Szenarien gefunden.\n")

    BASELINE_DIR.mkdir(parents=True, exist_ok=True)

    baseline_meta = {
        "erstellt_am": datetime.utcnow().isoformat(),
        "skill_fingerprint": skill_fingerprint,
        "gemini_model": GEMINI_MODEL,
        "szenarien": [],
    }

    for scenario in scenarios:
        sid = scenario["id"]
        print(f"Fuehre Szenario aus: {sid} - {scenario['name']}")
        print(f"  Prompt: {scenario['prompt'][:80]}...")

        output = run_scenario_with_gemini(skill_content, scenario, model)

        output_path = BASELINE_DIR / f"{sid}.txt"
        output_path.write_text(output, encoding="utf-8")
        print(f"  Gespeichert: {output_path}")

        baseline_meta["szenarien"].append({
            "id": sid,
            "name": scenario["name"],
            "output_fingerprint": compute_fingerprint(output),
            "output_laenge": len(output),
        })
        print()

    meta_path = BASELINE_DIR / "baseline_meta.json"
    meta_path.write_text(json.dumps(baseline_meta, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Baseline-Metadaten gespeichert: {meta_path}")
    print(f"\nBaseline erfolgreich erstellt mit {len(scenarios)} Szenarien.")
    print("Diese Baseline ist jetzt der Vergleichsmassstab fuer alle kuenftigen Skill-Aenderungen.")


if __name__ == "__main__":
    main()
