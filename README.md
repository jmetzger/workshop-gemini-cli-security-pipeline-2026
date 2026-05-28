# Workshop: Gemini CLI — Sicher betreiben & automatisiert verbessern (2 Tage)

## Agenda

  1. Einstieg
     * [DORA-Einordnung](docs/dora-overview.md)

  1. Gemini CLI absichern: Zentrale Security-Settings
     * [Uebung: Gemini CLI absichern ueber zentrale Settings](docs/uebung-gemini-cli-absichern.md)

  1. Gehaertetes Gemini-CLI-Image bauen
     * [Uebung: Image lokal bauen, scannen und haerten](docs/uebung-image-haerten.md)

  1. Gemini-CLI-Image auf Sicherheitsluecken scannen
     * [CVE-Scan: Schwachstellen in Paketen und Secrets erkennen](docs/uebung-image-haerten.md#schritt-3-lokal-mit-trivy-scannen)
     * [CIS-Scan: Docker Benchmark — Konfigurationsqualitaet pruefen](docs/uebung-image-haerten.md#schritt-4-gitlab-cicd-pipeline-mit-trivy)

  1. Verstehen, messen, Baseline setzen
     * [Uebung: LLM Prompt Injection — Verstehen, Testen, Abfangen](docs/uebung-llm-injection.md)
     * [Guardrails setzen und pruefen](docs/uebung-llm-injection.md#guardrails-pruefen--verifikation-mit-tests)

  1. Automatisiert verbessern — Pipeline als Verbesserungsmotor
     * GitLab Pipeline aufsetzen
     * MR-Schleife: Schrittweise verbessern
     * DORA-Nachweis: Was die Pipeline automatisch produziert

  1. Skill-Regression automatisch erkennen (Hermes 2.0)
     * [Phase 1 — Reflective Phase: Golden Baseline erstellen](hermes-skill-regression/uebung-01-baseline/README.md)
     * [Phase 2 — Execution in Sandbox: Skill ausfuehren & testen](hermes-skill-regression/uebung-02-regression/README.md)
     * [Phase 3 — Independent Verification: Gemini-Judge bewertet](hermes-skill-regression/uebung-03-pipeline/README.md)

  1. KI-Nutzung messen — Sind wir schneller geworden?
     * [Velocity-Messung: Cycle Time Vorher/Nachher mit GitLab](docs/ki-velocity-messung.md)

  1. Abschluss
     * Was habt ihr gebaut?
