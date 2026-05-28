---
name: workshop-training
description: Best Practices fuer Workshop- und Training-Uebungen. Enthaelt Format, Struktur, Cluster-Zugang und PDF-Generierung fuer alle Workshop- und Trainings-Repositories (Kubernetes, Docker, Security, etc.). Nutze diesen Skill wenn Uebungen erstellt, bearbeitet oder ein PDF generiert werden soll.
---

# Workshop & Training Skill

Dieser Skill enthaelt Best Practices fuer alle Workshop- und Trainings-Repositories.

## Uebungsordner

Uebungen werden im thematisch passenden Unterordner des jeweiligen Repositories erstellt,
z.B. `kubectl-examples/`, `kubernetes-security/`, `docker/`.

## Nummerierung (Kubernetes-Workshops)

| Nummernbereich | Thema |
|----------------|-------|
| 01-02 | Pods, ReplicaSets |
| 03 | Deployments, Services |
| 04-05 | Ingress |
| 06-07 | ConfigMaps, Secrets |
| 08 | Sealed Secrets |
| 10-12 | StatefulSet, Jobs, CronJobs |
| 13-14 | DaemonSets |
| 15 | Exec |
| 16-19 | Security, Policy (unprivileged, PDB, Affinity) |
| 20+ | Weitere Policy-Themen (ResourceQuota, LimitRange, etc.) |

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
# vi 01-dateiname.yaml
apiVersion: v1
kind: ...
metadata:
  name: my-resource
  namespace: mein-namespace
spec:
  ...
```

```
kubectl apply -f .
```

## Schritt N: Test/Exploration

```
kubectl get ...
kubectl describe ...
```

## Aufraeumen

```
kubectl delete namespace ...
```
```

### Wichtige Konventionen

1. **Namespace Strategie**:
   - Verwende einen festen Namespace-Namen fuer deine Ressourcen
   - Beispiel: `mein-namespace`, `workshop-namespace`
   - Der Namespace kann direkt im Manifest definiert werden

2. **Namespace im Manifest**: Namespace direkt in der Manifest-Datei angeben
   - RICHTIG: `namespace: mein-namespace` im Manifest
   - AUCH MOEGLICH: `kubectl apply -f . -n mein-namespace`

3. **Immer `kubectl apply -f .`**: Alle Manifests im Verzeichnis anwenden

4. **Manifest-Dateien nummerieren**: `01-resourcequota.yaml`, `02-pod1.yaml`, etc.
   - Dateiendung: `.yaml`

5. **Keine Umlaute in Dateien**: Verwende `ae`, `oe`, `ue`, `ss` statt Umlaute
   - Grund: Kompatibilitaet mit verschiedenen Terminals

6. **Code-Bloecke ohne Sprach-Annotation**: Verwende ``` ohne `bash` oder `yaml`

7. **Erwartete Fehler dokumentieren**: Bei Tests zeigen was schiefgehen soll

8. **Aufraeumen am Ende**: Immer Namespace loeschen als letzten Schritt

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

## Verifizierung vor Commit

1. Alle erwarteten Ausgaben im Terminal gesehen
2. Aufraeumen funktioniert
3. **Uebung in README.md Agenda eintragen**
4. Commit und Push

## SVG-Grafiken einbinden

SVG-Code gehoert **niemals inline** in eine Markdown-Datei.
Stattdessen immer als **externe Datei** unter `/images/` ablegen und per `![]()` einbinden.

**WICHTIG:** Pfad immer mit fuehrendem `/` angeben:

```markdown
![Auth Flow in Kubernetes](/images/auth-flow.svg)
```

## Dokumentation aus anderen Projekten uebernehmen

1. Dateien ins richtige Verzeichnis kopieren
2. README.md aktualisieren (Link einfuegen)
3. Beides zusammen committen und pushen
