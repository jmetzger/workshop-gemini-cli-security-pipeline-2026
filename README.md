# Workshop: Gemini CLI — Sicher betreiben & automatisiert verbessern (2 Tage)

## Agenda

  1. Einstieg
     * [DORA-Einordnung](docs/dora-overview.md)

  1. Gemini CLI absichern: Nur Images aus privater Registry
     * [Uebung: Gemini CLI nur aus privater Registry laden](docs/uebung-private-registry.md)
     * Gemini CLI lokal aus Quellcode bauen (Dockerfile)
     * Docker Daemon konfigurieren: registry-mirrors (Linux & Windows)
     * Docker Content Trust (DCT) aktivieren
     * Verifikation: Pull von Docker Hub schlaegt fehl

  1. Tag 1: Verstehen, messen, Baseline setzen
     * Gemini CLI lokal verstehen & nutzen
     * Baseline messen: Der Ausgangszustand dokumentieren
     * Guardrails: Was darf der Agent — und wie teste ich das?

  1. Automatisiert verbessern — Pipeline als Verbesserungsmotor
     * GitLab Pipeline aufsetzen
     * MR-Schleife: Schrittweise verbessern
     * Guardrails in die Pipeline integrieren
       * [Uebung 1: Golden Baseline erstellen](../reverse-engineer-hermes-2-0-skills-improvement/uebung-01-baseline/README.md)
       * [Uebung 2: Regression Detection mit Gemini-Judge](../reverse-engineer-hermes-2-0-skills-improvement/uebung-02-regression/README.md)
       * [Uebung 3: CI/CD Pipeline mit allen 3 Phasen](../reverse-engineer-hermes-2-0-skills-improvement/uebung-03-pipeline/README.md)
     * DORA-Nachweis: Was die Pipeline automatisch produziert
     * Abschluss: Was habt ihr gebaut?
