---
name: workshop-training
description: Best Practices fuer Workshop- und Training-Uebungen. Enthaelt Format, Struktur, Cluster-Zugang und PDF-Generierung fuer alle Workshop- und Trainings-Repositories (Kubernetes, Docker, Security, etc.). Nutze diesen Skill wenn Uebungen erstellt, bearbeitet oder ein PDF generiert werden soll.
---

# Workshop & Training Skill

Dieser Skill enthaelt Best Practices fuer alle Workshop- und Trainings-Repositories
(Kubernetes, Docker, Security und weitere Technologien).

## Uebungsordner

Uebungen werden im thematisch passenden Unterordner des jeweiligen Repositories erstellt,
z.B. `kubectl-examples/`, `kubernetes-security/`, `docker/`.

## Nummerierung (Kubernetes-Workshops)

Die Nummerierung der Uebungen folgt einem festen Schema:

| Nummernbereich | Thema                                               |
|----------------|-----------------------------------------------------|
| 01-02          | Pods, ReplicaSets                                   |
| 03             | Deployments, Services                               |
| 04-05          | Ingress                                             |
| 06-07          | ConfigMaps, Secrets                                 |
| 08             | Sealed Secrets                                      |
| 10-12          | StatefulSet, Jobs, CronJobs                         |
| 13-14          | DaemonSets                                          |
| 15             | Exec                                                |
| 16-19          | Security, Policy (unprivileged, PDB, Affinity)      |
| 20+            | Weitere Policy-Themen (ResourceQuota, LimitRange)   |

## Uebungs-Format

### Struktur

```markdown
# Titel der Uebung

## Hintergrund (optional)

Kurze Erklaerung des Konzepts, evtl. Tabelle mit Optionen.

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests
cd manifests
mkdir XX-thema
cd XX-thema
```

## Schritt 2: Ressource erstellen

```
# vi 01-dateiname.yml
apiVersion: v1
kind: ...
metadata:
  name: my-resource
spec:
  ...
```

```
kubectl apply -f . -n <prefix>-<dein-name>
```

## Schritt N: Test/Exploration

```
kubectl get ...
kubectl describe ...
```

**Erwarteter Fehler:** (wenn relevant)
```
Error from server (Forbidden): ...
```

## Aufraeumen

```
kubectl delete namespace ...
```

## Zusammenfassung (optional)

| Szenario | Ergebnis |
|----------|----------|
| ... | Akzeptiert/Abgelehnt |
```

### Wichtige Konventionen

1. **Namespace Strategie**:
   - **kubectl-examples/ (geteilte Cluster)**: Verwende `<prefix>-<dein-name>` Format
     - Beispiel: `resource-<dein-name>` (Teilnehmer ersetzen mit eigenem Namen)
     - Der Prefix sollte zum Thema passen (z.B. `resource-`, `ingress-`, `secret-`)
   - **gitops/flux/ (eigene Cluster)**: Verwende feste Namespace-Namen ohne `<dein-name>`
     - Beispiel: `flux-system`, `applications`, `monitoring`
     - Grund: Jeder Teilnehmer hat sein eigenes Cluster, keine Kollisionen

2. **Namespace NICHT im Manifest**: Namespace bei `kubectl apply` angeben
   - FALSCH: `namespace: myns` im Manifest
   - RICHTIG: `kubectl apply -f . -n resource-<dein-name>`

3. **Immer `kubectl apply -f .`**: Alle Manifests im Verzeichnis anwenden

4. **Manifest-Dateien nummerieren**: `01-resourcequota.yml`, `02-pod1.yml`, etc.
   - Dateiendung: `.yml` (nicht `.yaml`)

5. **Keine Umlaute in Dateien**: Verwende `ae`, `oe`, `ue`, `ss` statt Umlaute
   - Grund: Kompatibilitaet mit verschiedenen Terminals

6. **Code-Bloecke ohne Sprach-Annotation**: Verwende ``` ohne `bash` oder `yaml`

7. **Erwartete Fehler dokumentieren**: Bei Tests zeigen was schiefgehen soll

8. **Aufraeumen am Ende**: Immer Namespace loeschen als letzten Schritt

## TEST-PFLICHT — Jede neue Uebung muss auf dem echten Cluster ausgefuehrt werden

**WICHTIG:** Eine Uebung gilt erst als fertig, wenn sie wirklich auf dem Cluster getestet wurde.

Das bedeutet konkret:
- Alle Befehle ausfuehren und Output pruefen
- Bei Sicherheitsuebungen: konkreten FAIL zeigen, Fix anwenden, PASS bestaetigen
- Aufraeumen funktioniert

## Cluster-Zugang fuer Tests

```bash
# Bastion-Host (als Trainer)
ssh -i ~/.ssh/id_ed25519_nopass root@161.35.210.204

# Als Teilnehmer tln1 testen
su - tln1
kubectl get nodes
```

## Agenda (README.md)

**WICHTIG:** Neue Uebungen muessen auch in der Agenda aufgenommen werden!

### Format fuer Agenda-Eintrag

```markdown
  1. Themenbereich
     * [Uebungstitel](pfad/zur/uebung.md)
```

## Verifizierung vor Commit

1. **Uebung auf echtem Cluster ausgefuehrt** (TEST-PFLICHT)
2. Alle erwarteten Ausgaben im Terminal gesehen
3. Aufraeumen funktioniert
4. **Uebung in README.md Agenda eintragen**
5. Commit und Push

## PDF generieren

PDFs werden ueber die GitHub Action im Repo `jmetzger/github-md2pdf` generiert.
Die Action liest das `README.md` des Ziel-Repos und erstellt daraus eine `README.pdf`.

### Workflow ausloesen

```bash
gh workflow run pdf-deployment.yml \
  --repo jmetzger/github-md2pdf \
  --field repository=<repo-name>
```

### Status pruefen

```bash
gh run list --repo jmetzger/github-md2pdf --limit 3
```

## SVG-Grafiken einbinden

SVG-Code gehoert **niemals inline** in eine Markdown-Datei.
Stattdessen immer als **externe Datei** unter `/images/` ablegen und per `![]()` einbinden.

Benennungsschema: `<thema>-<beschreibung>.svg`, nur Kleinbuchstaben und Bindestriche.

**WICHTIG:** Pfad immer mit fuehrendem `/` angeben:

```markdown
![Auth Flow in Kubernetes](/images/auth-flow.svg)
```

## Dokumentation aus anderen Projekten uebernehmen

1. Dateien ins richtige Verzeichnis kopieren
2. README.md aktualisieren (Link einfuegen)
3. Beides zusammen committen und pushen
