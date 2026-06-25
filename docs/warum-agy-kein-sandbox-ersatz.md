# Warum agy (antigravity) kein Ersatz fuer gemini --sandbox ist

## Kurze Antwort

`agy --sandbox` verwendet intern **kein Docker**. Es fehlt die Container-Isolierung,
die `gemini --sandbox` sicherheitskritisch macht.

---

## Was gemini --sandbox macht

`gemini --sandbox` startet jeden Tool-Aufruf (RunCommand, WriteFile, etc.) in einem
**frischen Docker-Container**:

```
gemini --sandbox "erstelle eine test.sh und fuehre sie aus"
```

Was intern passiert:

```
docker run --rm --network none -v /tmp/sandbox:/workspace gemini-sandbox:latest bash -c "..."
```

Die Konsequenz:

| Eigenschaft | Mit --sandbox |
|---|---|
| Prozess-Isolierung | Docker-Container (eigener PID-Namespace) |
| Dateisystem | Nur gemountetes /workspace sichtbar |
| Netzwerk | Per Default deaktiviert (--network none) |
| Schaden nach Ausfuehren | Container wird zerstoert, Host bleibt sauber |
| Rootfs des Hosts | Nicht erreichbar |

---

## Was agy --sandbox macht

`agy` (antigravity) ist ein Python-Paket, das Gemini CLI in einem Python-Prozess
wrappt. Der `--sandbox`-Flag in agy aktiviert **keine Docker-Isolierung**, sondern
einen einfachen Prozess-Wrapper ohne Namespaces und ohne Container:

```
agy --sandbox "erstelle eine test.sh und fuehre sie aus"
```

Was intern passiert: Das Tool laeuft weiterhin im **selben Prozess** (oder einem
direkten Child-Prozess) mit Zugriff auf das Dateisystem des Hosts.

| Eigenschaft | agy --sandbox |
|---|---|
| Prozess-Isolierung | Nein — gleicher User, gleicher Namespace |
| Dateisystem | Voller Zugriff auf den Host |
| Netzwerk | Nicht eingeschraenkt |
| Schaden nach Ausfuehren | Bleibt erhalten (kein Container-Reset) |
| Rootfs des Hosts | Erreichbar |

---

## Vergleich auf einen Blick

| Kriterium | gemini --sandbox | agy --sandbox |
|---|---|---|
| Docker verwendet | **Ja** | **Nein** |
| Dateisystem-Isolierung | Ja (nur /workspace) | Nein |
| Netzwerk-Isolierung | Ja (--network none) | Nein |
| Schadcode-Eindaemmung | Ja | Nein |
| Geeignet fuer Prod-Settings | Ja | Nein |

---

## Warum das sicherheitskritisch ist

Ohne Docker-Isolierung kann ein kompromittierter oder manipulierter Prompt:

- Dateien ausserhalb des Arbeitsverzeichnisses lesen oder loeschen
- Netzwerkverbindungen aufbauen (z.B. Daten exfiltrieren)
- Prozesse auf dem Host starten
- Persistent Backdoors anlegen (keine Zerstoerung des "Containers")

Die Sandbox-Eigenschaft von gemini ist kein Feature fuer Komfort — sie ist die
**einzige technische Grenze zwischen dem LLM-Agenten und dem Host-System**.

---

## Fazit

`agy --sandbox` ist kein Sicherheits-Feature im Sinne der Gemini-CLI-Sandbox.
Der Begriff "sandbox" ist hier irrefuehrend: Es handelt sich um einen
Laufzeit-Modus fuer agy, nicht um Container-basierte Isolierung.

**Wer echte Sandbox-Sicherheit braucht, muss `gemini --sandbox` verwenden** —
und sicherstellen, dass Docker tatsaechlich installiert und gestartet ist.

---

## Wie gemini --sandbox intern funktioniert

Bevor man Alternativen baut, muss man verstehen was tatsaechlich passiert —
denn ein simples "CLI in Docker wrappen" loest das Problem nicht.

### Die echte Architektur

```
+------------------+          +-----------------------------+
|  Host-Prozess    |  stdio   |  Docker-Container           |
|  gemini CLI      |<-------->|  gemini CLI (Kind-Prozess)  |
|  - API-Verbindung|  pipe    |  - RunCommand               |
|  - Orchestrierung|          |  - WriteFile / ReadFile      |
+------------------+          |  - Netzwerk: none           |
         |                    +-----------------------------+
         v                             ^
  Gemini API (Cloud)         Workspace-Volume
                             (nur Projektordner gemountet)
```

Konkret:

1. `gemini --sandbox` startet auf dem **Host** und baut die Verbindung zur Gemini API auf.
2. Gleichzeitig spawnt es **sich selbst als Kind-Prozess** in einem Docker-Container.
3. Host und Container kommunizieren ueber **stdin/stdout-Pipes**.
4. Alle Tool-Ausfuehrungen (RunCommand, WriteFile, etc.) laufen im Container —
   der keine Netzwerkverbindung hat und nur das Projektverzeichnis sieht.
5. Der Host-Prozess leitet die Ergebnisse weiter zur Gemini API.

Ein einfaches `docker run agy ...` loest das Problem daher **nicht**:
Der gesamte Prozess inkl. API-Verbindung waere im Container eingesperrt,
oder der Container muss Netzwerkzugriff bekommen — und damit faellt die Isolierung weg.

---

