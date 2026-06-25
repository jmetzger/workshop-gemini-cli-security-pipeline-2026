# Uebungsvorbereitung

## Schritt 1: Repository clonen

Einmalig zu Beginn des Workshops — fuer alle Teilnehmer derselbe Pfad:

```bash
cd && mkdir exercises && git clone https://github.com/jmetzger/workshop-gemini-cli-security-pipeline-2026.git exercises
```

Danach immer aus diesem Verzeichnis arbeiten:

```bash
cd ~/exercises
```

## Schritt 2: Gemini CLI pruefen

Version pruefen — muss vorhanden und >= 0.40 sein:

```bash
gemini --version
```

## Schritt 3: Verbindung zu Gemini testen

```bash
echo "Antworte nur mit: OK" | gemini
```

Erwartete Ausgabe: `OK` (oder eine kurze Bestaetigung).
Wenn hier ein Fehler erscheint → API Key pruefen:

```bash
echo $GEMINI_API_KEY
```

Der Key muss gesetzt sein. Falls nicht:

```bash
source /etc/profile.d/gemini-api.sh
```
