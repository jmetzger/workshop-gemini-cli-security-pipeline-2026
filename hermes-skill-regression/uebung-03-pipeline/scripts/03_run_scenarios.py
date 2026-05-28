#!/usr/bin/env python3
"""
Uebung 3 / Pipeline Phase 2: Szenarien ausfuehren

Wird von der GitHub Actions Pipeline aufgerufen.
Laedt die geaenderten Skills und fuehrt alle Test-Szenarien aus.
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
    sys.exit(1)


SCENARIOS_PATH = Path(__file__).parent.parent.parent / "uebung-01-baseline/tests/scenarios.yaml"
OUTPUT_DIR = Path("outputs")
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.0-flash")


def load_scenarios():
    with open(SCENARIOS_PATH, encoding="utf-8") as f:
        return yaml.safe_load(f)["scenarios"]


def run_scenario(skill_content: str, scenario: dict, model) -> str:
    prompt = f"""Du arbeitest mit dem folgenden Skill-Kontext:

---SKILL START---
{skill_content}
---SKILL ENDE---

AUFGABE: {scenario['prompt']}"""
    return model.generate_content(prompt).text


def main():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("FEHLER: GEMINI_API_KEY nicht gesetzt.")
        sys.exit(1)

    changed_skills_env = os.environ.get("CHANGED_SKILLS", "")
    changed_skills = [s.strip() for s in changed_skills_env.split() if s.strip()]

    if not changed_skills:
        print("Keine geaenderten Skills angegeben. Verwende Standard-Skill.")
        changed_skills = ["skills/workshop-training/SKILL.md"]

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel(GEMINI_MODEL)
    scenarios = load_scenarios()
    OUTPUT_DIR.mkdir(exist_ok=True)

    for skill_path_str in changed_skills:
        skill_path = Path(skill_path_str)
        if not skill_path.exists():
            print(f"WARNUNG: {skill_path} nicht gefunden, ueberspringe.")
            continue

        skill_name = skill_path.stem
        skill_content = skill_path.read_text(encoding="utf-8")
        print(f"Fuehre Szenarien aus fuer: {skill_path}")

        for scenario in scenarios:
            sid = scenario["id"]
            output = run_scenario(skill_content, scenario, model)
            out_path = OUTPUT_DIR / f"{skill_name}__{sid}.txt"
            out_path.write_text(output, encoding="utf-8")
            print(f"  {sid}: {len(output)} Zeichen → {out_path}")

    meta = {"model": GEMINI_MODEL, "skills_getestet": changed_skills}
    (OUTPUT_DIR / "run_meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(f"\nOutputs gespeichert in: {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
