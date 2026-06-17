# Workshop: Gemini CLI Security Pipeline

## Secrets-Handling

Dieses Repo enthält keine echten Secrets. Die Datei `docs/uebung-image-haerten.md`
enthält absichtlich einen **fake** Gemini-API-Key — das ist das Lernziel der Übung
(Trivy soll ihn erkennen). Den Key nicht rotieren oder entfernen.

Falls Secrets benötigt werden (z.B. für lokale Tests):

```bash
# .env anlegen, dann sofort verschlüsseln
sops --encrypt --input-type dotenv --output-type dotenv .env > .env.enc && rm .env
```

`.env` ist in `.gitignore` — nie ein plain `.env` committen.

## Projektstruktur

```
docs/               # Übungsanleitungen (Markdown)
scripts/            # Install-Scripts (install-gemini-cli.sh, install-agy.sh)
tests/              # Automatisierte Tests (behavioral, guardrails, injection, smoke)
hermes-skill-regression/  # Skill-Regression Pipeline (3 Übungen)
```

## Tests ausführen

```bash
bash tests/run_all.sh
```

## Wichtige Umgebungsvariable

`GEMINI_API_KEY` — wird von `scripts/install-gemini-cli.sh` in
`/etc/profile.d/gemini-api.sh` eingetragen (nur auf dem Workshop-Server).
