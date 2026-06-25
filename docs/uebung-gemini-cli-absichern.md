# Uebung: Gemini CLI absichern ueber zentrale Settings

## Hintergrund

Gemini CLI liest seine Konfiguration aus mehreren Settings-Dateien, die in einer
festen Prioritaetsreihenfolge ausgewertet werden. Fuer den Unternehmenseinsatz
bedeutet das: Admins setzen zentrale Defaults, die Nutzer nur teilweise ueberschreiben
koennen.

### Konfigurations-Hierarchie (niedrigste → hoechste Prioritaet)

| Ebene | Linux | Windows |
|---|---|---|
| System-Defaults (Admin) | `/etc/gemini-cli/system-defaults.json` | `C:\ProgramData\gemini-cli\system-defaults.json` |
| Benutzer | `~/.gemini/settings.json` | `%APPDATA%\GeminiCli\settings.json` |
| Projekt | `.gemini/settings.json` im Projektordner | identisch |
| System-Policy (Admin, hoechste Prio) | `/etc/gemini-cli/settings.json` | `C:\ProgramData\gemini-cli\settings.json` |

Admins setzen Pflicht-Einstellungen in der **System-Policy** (`settings.json`) —
diese ueberschreibt alles andere.

---

## Die wichtigsten Security-Settings

```
{
  "security": {
    "disableYoloMode": true,
    "disableAlwaysAllow": true
  },
  "tools": {
    "sandbox": "docker",
    "core": ["read_file", "write_file", "run_shell_command", "search_files"],
    "sandboxNetworkAccess": false
  },
  "mcp": {
    "allowed": []
  },
  "telemetry": {
    "logPrompts": false
  }
}
```

| Setting | Bedeutung |
|---|---|
| `security.disableYoloMode` | Verhindert automatische Genehmigung aller Aktionen |
| `security.disableAlwaysAllow` | Entfernt "Immer erlauben"-Option aus Dialogen |
| `tools.sandbox` | Fuehrt Tools isoliert in Docker aus |
| `tools.core` | Allowlist: nur diese Built-in-Tools sind verfuegbar |
| `tools.sandboxNetworkAccess` | Netzwerkzugriff aus Sandbox heraus sperren |
| `mcp.allowed` | Leere Liste: keine externen MCP-Server erlaubt |
| `telemetry.logPrompts` | Kein Logging von Prompts (Datenschutz) |

---

## Schritt 1: Zentrale Settings-Datei anlegen

### Linux

```
sudo mkdir -p /etc/gemini-cli
sudo vi /etc/gemini-cli/settings.json
```

Inhalt einfuegen:

```
{
  "security": {
    "disableYoloMode": true,
    "disableAlwaysAllow": true
  },
  "tools": {
    "sandbox": "docker",
    "core": ["read_file", "write_file", "run_shell_command", "search_files"],
    "sandboxNetworkAccess": false
  },
  "mcp": {
    "allowed": []
  },
  "telemetry": {
    "logPrompts": false
  }
}
```

Berechtigungen setzen (nur root darf schreiben):

```
sudo chmod 644 /etc/gemini-cli/settings.json
sudo chown root:root /etc/gemini-cli/settings.json
```

### Windows

PowerShell als Administrator:

```
New-Item -ItemType Directory -Force -Path "C:\ProgramData\gemini-cli"

$settings = @'
{
  "security": {
    "disableYoloMode": true,
    "disableAlwaysAllow": true
  },
  "tools": {
    "sandbox": "docker",
    "core": ["read_file", "write_file", "run_shell_command", "search_files"],
    "sandboxNetworkAccess": false
  },
  "mcp": {
    "allowed": []
  },
  "telemetry": {
    "logPrompts": false
  }
}
'@

$settings | Out-File -FilePath "C:\ProgramData\gemini-cli\settings.json" -Encoding UTF8
```

Schreibschutz fuer Nicht-Admins:

```
icacls "C:\ProgramData\gemini-cli\settings.json" /inheritance:r /grant:r "BUILTIN\Administrators:(F)" /grant:r "Everyone:(R)"
```

---

## Schritt 2: Sandbox prüfen 

```
gemini
```

```
# in gemini -> about
# Sandbox muss auftauchen 
/about
/quit 
```





Oder die Settings-Datei direkt lesen:

```
cat /etc/gemini-cli/settings.json
```

Sandbox-Eintrag pruefen:

```
grep sandbox /etc/gemini-cli/settings.json
```

Erwartete Ausgabe:

```
    "sandbox": "docker",
```

---

## Schritt 3: Verifikation — disableYoloMode greift

Ohne die zentrale Settings-Datei kann ein Nutzer YOLO-Mode aktivieren:

```
gemini --yolo
```

Mit gesetztem `disableYoloMode: true` schlaegt das fehl:

```
Error: YOLO mode is disabled by policy
```

Versuch, "Immer erlauben" zu aktivieren — ebenfalls geblockt:

```
Permission dialog shows no "Always allow" option
```

---

## Schritt 4: Nutzer-Settings ueberschreiben testen

Ein Nutzer versucht, die Sandbox lokal zu deaktivieren:

```
# ~/.gemini/settings.json
{
  "tools": {
    "sandbox": false
  }
}
```

Da die System-Policy hoehere Prioritaet hat, gilt weiterhin `sandbox: docker`.
Das bestaetigt ein Blick in die System-Settings-Datei:

```
cat /etc/gemini-cli/settings.json
```

Erwartete Ausgabe (Nutzer-Settings werden ignoriert, System-Settings bleiben aktiv):

```
    "sandbox": "docker",
```

---

## Zusammenfassung

| Massnahme | Linux | Windows |
|---|---|---|
| Zentrale Policy anlegen | `/etc/gemini-cli/settings.json` | `C:\ProgramData\gemini-cli\settings.json` |
| YOLO-Mode sperren | `security.disableYoloMode: true` | identisch |
| "Immer erlauben" sperren | `security.disableAlwaysAllow: true` | identisch |
| Sandbox erzwingen | `tools.sandbox: "docker"` | identisch |
| Tool-Allowlist setzen | `tools.core: [...]` | identisch |
| Externe MCP-Server sperren | `mcp.allowed: []` | identisch |
| Prompt-Logging abschalten | `telemetry.logPrompts: false` | identisch |
