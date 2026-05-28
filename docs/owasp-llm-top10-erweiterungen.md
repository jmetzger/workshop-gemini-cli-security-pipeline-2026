# OWASP LLM Top 10 (2025) — Noch nicht abgedeckte Themen

Referenz: [OWASP Top 10 for LLM Applications 2025 — offizielles PDF (v2025, Stand Nov 2024)](https://owasp.org/www-project-top-10-for-large-language-model-applications/assets/PDF/OWASP-Top-10-for-LLMs-v2025.pdf)

Bereits vollstaendig abgedeckt: **LLM01:2025 Prompt Injection**
(→ [Uebung LLM Prompt Injection](uebung-llm-injection.md), [Hooks Guardrails](uebung-hooks-guardrails.md))

---

## [LLM02:2025 — Sensitive Information Disclosure](https://genai.owasp.org/llmrisk/llm022025-sensitive-information-disclosure/)

Das LLM gibt versehentlich Geheimnisse aus (z.B. Passwoerter, API-Keys, persoenliche Daten).
Gegenmaßnahme hier: Ein Hook prueft nach jedem Tool-Aufruf den Output und filtert solche
Secrets raus.

---

## [LLM05:2025 — Improper Output Handling](https://genai.owasp.org/llmrisk/llm052025-improper-output-handling/)

Der Output des LLM wird ungeprueft weiterverwendet. Im Demo-Beispiel landet Gemini-Output
direkt in einem `eval()` — ein Angreifer kann so eigenen Code einschleusen (Shell Injection).
Loesung: strukturierte, fest definierte Ausgabeformate statt frei interpretierbarem Text.

---

## [LLM07:2025 — System Prompt Leakage](https://genai.owasp.org/llmrisk/llm072025-system-prompt-leakage/)

Die internen Anweisungen (System Prompt, z.B. die `GEMINI.md`) werden ausgeplaudert. Damit
sieht ein Angreifer, wie das System „tickt", und kann es gezielter manipulieren. Test dafuer:
promptfoo mit „Leakage-Probes", die versuchen, den Prompt herauszulocken.

---

## [LLM10:2025 — Unbounded Consumption](https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/)

Das LLM verbraucht unbegrenzt Ressourcen — viele/teure Anfragen treiben die Kosten hoch
(„Denial of Wallet", das Geld-Pendant zu Denial of Service). Schutz: Timeout und Token-Limit
in der Pipeline.

---

## Nicht abgedeckt und nicht relevant fuer diesen Workshop

| # | Titel | Begruendung |
|---|-------|-------------|
| LLM03 | Supply Chain | Gilt fuer Model-Provenance und Plugins — hier verwenden wir Googles Gemini direkt, kein Fine-Tuning oder externe Modelle |
| LLM04 | Data and Model Poisoning | Erfordert eigenes Training / Fine-Tuning — nicht applicable fuer Gemini CLI |
| LLM06 | Excessive Agency | Durch `BeforeTool`-Hooks bereits abgedeckt (→ [Hooks Guardrails](uebung-hooks-guardrails.md)) |
| LLM08 | Vector and Embedding Weaknesses | Nur relevant bei eigenen RAG-Systemen — kein eigener Vektor-Store im Workshop |
| LLM09 | Misinformation | Output-Qualitaet, kein Security-Angriffsvektor im klassischen Sinne |
