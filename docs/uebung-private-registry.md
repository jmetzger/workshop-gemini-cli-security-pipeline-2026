# Uebung: Gemini CLI nur aus privater Registry laden

## Hintergrund

Wer `docker pull` uneingeschraenkt erlaubt, kann sich beliebige Images von Docker Hub
oder anderen oeffentlichen Registries holen — ein klassisches Supply-Chain-Risiko.
Ziel dieser Uebung: Docker so konfigurieren, dass Images **ausschliesslich** aus einer
internen/privaten Registry (Sandbox) bezogen werden duerfen.

Zwei Mechanismen greifen ineinander:

| Mechanismus | Wirkung |
|---|---|
| `registry-mirrors` in `daemon.json` | Leitet alle Pulls auf die private Registry um |
| `Docker Content Trust (DCT)` | Erlaubt nur signierte Images |
| Netzwerksperre (Firewall/proxy) | Blockiert `docker.io` auf Netzwerkebene |

In dieser Uebung setzen wir die Daemon-Konfiguration und bauen Gemini CLI lokal.

---

## Schritt 1: Gemini CLI lokal bauen

Statt ein fertiges Image aus Docker Hub zu ziehen, bauen wir es selbst aus dem
Quellcode. Das gibt uns volle Kontrolle ueber den Inhalt des Images.

```
git clone https://github.com/google-gemini/gemini-cli
cd gemini-cli
```

Dockerfile anlegen (falls noch nicht vorhanden):

```
# vi Dockerfile
FROM node:22-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
RUN npm run build 2>/dev/null || true
ENTRYPOINT ["node", "bundle/gemini.js"]
```

Image bauen und taggen:

```
docker build -t gemini-cli:local .
```

Kurz testen:

```
docker run --rm gemini-cli:local --version
```

---

## Schritt 2: Image in private Registry pushen

Wir verwenden als Beispiel eine lokale Registry (z. B. GitLab Container Registry,
Harbor oder Nexus). Adresse: `registry.example.internal`

```
docker tag gemini-cli:local registry.example.internal/tools/gemini-cli:1.0
docker login registry.example.internal
docker push registry.example.internal/tools/gemini-cli:1.0
```

---

## Schritt 3: Docker Daemon absichern

### Linux

Datei `/etc/docker/daemon.json` anlegen oder anpassen:

```
sudo vi /etc/docker/daemon.json
```

Inhalt:

```
{
  "registry-mirrors": ["https://registry.example.internal"],
  "insecure-registries": [],
  "live-restore": true
}
```

Daemon neu starten:

```
sudo systemctl restart docker
```

Verifikation — alle Pulls gehen jetzt ueber den Mirror:

```
docker info | grep -A5 "Registry Mirrors"
```

### Windows (Docker Desktop)

Docker Desktop > **Settings** > **Docker Engine**

Dort den JSON-Block anpassen:

```
{
  "registry-mirrors": ["https://registry.example.internal"]
}
```

**Apply & Restart** klicken.

Alternativ direkt in der Datei:
`%USERPROFILE%\AppData\Roaming\Docker\daemon.json`

Neustart ueber die Docker-Desktop-Tray-Icon: *Restart*.

---

## Schritt 4: Docker Content Trust aktivieren (optional, haertere Variante)

DCT verweigert den Pull von nicht-signierten Images komplett.

**Linux (Session oder dauerhaft):**

```
export DOCKER_CONTENT_TRUST=1
```

Dauerhaft in `~/.bashrc` oder `/etc/environment`:

```
echo 'export DOCKER_CONTENT_TRUST=1' >> ~/.bashrc
```

**Windows (PowerShell):**

```
$env:DOCKER_CONTENT_TRUST = "1"
```

Dauerhaft:

```
[System.Environment]::SetEnvironmentVariable("DOCKER_CONTENT_TRUST", "1", "Machine")
```

Pull ohne Signatur schlaegt nun fehl:

```
docker pull alpine:latest
```

Erwarteter Fehler:

```
Error: remote trust data does not exist for docker.io/library/alpine
```

---

## Schritt 5: Verifikation

Image aus privater Registry laden — das muss funktionieren:

```
docker pull registry.example.internal/tools/gemini-cli:1.0
```

Pull direkt von Docker Hub — das soll fehlschlagen (wenn Netzwerksperre aktiv):

```
docker pull nginx:latest
```

Erwarteter Fehler (bei aktivem Mirror + Netzwerksperre):

```
Error response from daemon: Get "https://registry-1.docker.io/...": dial tcp: connection refused
```

---

## Zusammenfassung

| Massnahme | Linux | Windows |
|---|---|---|
| `registry-mirrors` setzen | `/etc/docker/daemon.json` + `systemctl restart docker` | Docker Desktop > Settings > Docker Engine |
| DCT aktivieren | `export DOCKER_CONTENT_TRUST=1` | `$env:DOCKER_CONTENT_TRUST = "1"` |
| Lokal bauen | `docker build -t ...` | identisch |
| In private Registry pushen | `docker push registry.example.internal/...` | identisch |

Die haerteste Absicherung kombiniert alle drei Schichten:
eigenes Build + Registry Mirror + Netzwerksperre auf `docker.io`.
