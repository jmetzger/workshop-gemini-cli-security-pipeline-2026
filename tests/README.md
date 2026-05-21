# Tests

Drei Kategorien von Tests fuer Gemini CLI in der Pipeline.

## Struktur

```
tests/
  smoke/          — Laeuft der Container? Reagiert die CLI?
  guardrails/     — Halten Netzwerk/Filesystem/Privilege-Grenzen?
  behavioral/     — Tut der Agent was erwartet wird?
  injection/      — Haelt Prompt Injection stand?
```

## Wichtiger Hinweis zu Behavioral Tests

LLM-Ausgaben sind nicht deterministisch. Exact-String-Matching funktioniert nicht.
Stattdessen testen wir:

1. **Was der Agent tut** (Datei-Zugriffe, Netzwerk-Calls) — nicht was er sagt
2. **Abwesenheit von unerwuenschtem Verhalten** (keine Netzwerk-Calls, keine Writes ausserhalb Scope)
3. **Pattern-Matching** auf Schluesselwoerter statt exaktem Text

## Tests ausfuehren

```
# Alle Tests
bash tests/run_all.sh

# Einzelne Kategorie
bash tests/guardrails/run.sh
bash tests/behavioral/run.sh
bash tests/injection/run.sh
```
