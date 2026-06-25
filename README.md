# Workshop: Gemini CLI — Sicher betreiben & automatisiert verbessern (2 Tage)

## Agenda 

 1. Einstieg
    * [DORA-Einordnung](docs/dora-overview.md)

 1. Überlegungen Antigravity cli
     * [Warum agy (antigravity) kein Ersatz fuer gemini --sandbox ist](docs/warum-agy-kein-sandbox-ersatz.md)

 1. Installation (gemini) - bereits vorbereitet
    * [Installation & Voraussetzungen - bash scripts/install-gemini-cli.sh](docs/installation.md)

 1. Gemini CLI absichern: Zentrale Security-Settings
     * [Uebung: Gemini CLI absichern ueber zentrale Settings](docs/uebung-gemini-cli-absichern.md)
   
 1. Gehaertetes Gemini-CLI-Image bauen
    * [Uebung: Image lokal bauen, scannen und haerten](docs/uebung-image-haerten.md)


## Backlog - Agenda
     
  1. Gemini-CLI-Image auf Sicherheitsluecken scannen
     * [CVE-Scan: Schwachstellen in Paketen und Secrets erkennen](docs/uebung-image-haerten.md#schritt-3-lokal-mit-trivy-scannen)
     * [CIS-Scan: GitLab CI/CD Pipeline mit Trivy und Kaniko](docs/uebung-gitlab-pipeline.md)

  1. LLM-Injections verhinden, testen und analysieren
     * [Uebung: LLM Prompt Injection — Verstehen, Testen, Abfangen](docs/uebung-llm-injection.md)
     * [Guardrails setzen und pruefen](docs/uebung-llm-injection.md#guardrails-pruefen--verifikation-mit-tests)

  1. Gemini CLI Hooks — als Guardrails Methode nutzen (konkretes Beispiel)
     * [Uebung: BeforeTool / AfterTool Hooks konfigurieren und testen](docs/uebung-hooks-guardrails.md)

  1. Skill-Regression automatisch erkennen (Hermes 2.0)
     * [Phase 1 — Reflective Phase: Golden Baseline erstellen](hermes-skill-regression/uebung-01-baseline/README.md)
     * [Phase 2 — Execution in Sandbox: Skill ausfuehren & testen](hermes-skill-regression/uebung-02-regression/README.md)
     * [Phase 3 — Independent Verification: Gemini-Judge bewertet](hermes-skill-regression/uebung-03-pipeline/README.md)

  1. gemini cli - image  -> automatisiert verbessern — Pipeline als Verbesserungsmotor
     * GitLab Pipeline aufsetzen
     * MR-Schleife: Schrittweise verbessern
     * DORA-Nachweis: Was die Pipeline automatisch produziert
    
  1. Best Practice Ausblick
     * Bugs aus Issues automatisiert/halbautomatisiet (mit gemini cli) in gitlab lösen
     * Bugs automatisiert finden und MR-Vorschlag mit gemini cli automatisiert erstellen lassen

  1. KI-Nutzung messen — Sind wir schneller geworden?
     * [Velocity-Messung: Cycle Time Vorher/Nachher mit GitLab](docs/ki-velocity-messung.md)

  1. OWASP LLM Top 10 — Was noch fehlt
     * [Noch nicht abgedeckte Schwachstellen aus dem OWASP LLM Top 10 (2025)](docs/owasp-llm-top10-erweiterungen.md)

  
