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

## Zukunftssicherheit: Was tun, wenn gemini CLI nicht mehr unterstuetzt wird?

Es gibt keine perfekte Loesung — jeder Ansatz hat einen echten Trade-off.

### Option 1: Docker-Sandbox als Feature in agy einbringen (Pull Request)

Da agy ebenfalls open source ist, ist der sauberste Weg ein
**Beitrag zum Upstream-Projekt**: Die Sandbox-Logik aus `sandbox.ts` in
agy portieren und als PR einreichen.

- Neue Features von agy kommen weiterhin automatisch
- Die Sandbox wird offiziell gepflegt, nicht als Fork
- Aufwand einmalig, kein dauerhafter Maintenance-Overhead

**Stand (Juni 2026):** Es gibt keinen offiziellen PR dafuer im
agy-Repository. Die Community hat Workarounds veroeffentlicht die agy
in Docker verpacken (z.B. dockerized-antigravity) — diese sind jedoch
**keine Sicherheitsloesung**: Sie verwenden `network_mode: host`,
`ipc: host` und erhoehte Rechte (SYS_ADMIN, seccomp unconfined), um
Chrome-OAuth und GUI-Darstellung zu ermoeglichen. Ein kompromittierter
Agent hat dort vollen Zugriff auf den Host. Keiner dieser Workarounds
ist ins Upstream-Projekt eingeflossen.

Das bedeutet: Diese Option ist **offen und ungenutzt** — wer die
Ressourcen hat, koennte hier einen echten Beitrag leisten.

Risiko: Google/das agy-Team muss den PR annehmen. Wenn sie Docker-Sandbox
bewusst weggelassen haben, wird der PR moeglicherweise abgelehnt.

### Option 2: Gemini CLI forken

Gemini CLI ist **open source (Apache 2.0)**. Der Fork behaelt die
Sandbox (`packages/cli/src/utils/sandbox.ts`) und kann unabhaengig
vom LLM-Backend betrieben werden.

**Ehrlicher Trade-off:**

| Aspekt | Fork |
|---|---|
| Sandbox-Feature | bleibt erhalten |
| Neue Features aus agy | kommen **nicht** automatisch |
| Security-Patches | muessen selbst backgeportet werden |
| Langfristiger Aufwand | hoch — eigene Codebasis |

Ein Fork lohnt sich nur, wenn intern Engineering-Kapazitaet vorhanden
ist, ihn aktiv zu pflegen.

### Option 3: Plattform mit eingebauter Docker-Isolierung

Wechsel auf eine Agentenplattform, die Docker-Isolierung als
Kernarchitektur mitbringt:

| Tool | Sandbox-Ansatz | Typ |
|---|---|---|
| **OpenHands** (ehemals OpenDevin) | Gesamter Agent in Docker | Web-Plattform + API |
| **SWE-agent** | Docker-Container pro Task | Python-Framework |

### Fazit

Die ehrlichste Antwort: Es gibt keinen kostenfreien Ausweg. Entweder
traegt man aktiv zum Upstream bei (Option 1, der beste Weg wenn er
funktioniert), pflegt einen Fork (Option 2, teuer), oder wechselt die
Plattform (Option 3, groesserer Einschnitt). Wer heute auf
`gemini --sandbox` setzt, sollte die Sandbox-Anforderung als
**Auswahlkriterium fuer den naechsten Tool-Wechsel** festschreiben.
