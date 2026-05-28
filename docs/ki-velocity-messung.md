# KI-Velocity-Messung: Sind wir durch Gemini CLI schneller geworden?

## Ziel

Nachweisbar messen ob das Team durch den Einsatz von Gemini CLI schneller
Merge Requests abschliesst. Kennzahl: **Durchschnittliche Cycle Time in Stunden**
(MR geoeffnet → MR gemergt), Vorher/Nachher-Vergleich.

---

## Was die Cycle Time aussagt

Die Cycle Time enthaelt alles: Coding-Zeit, Review-Wartezeit, Korrekturen, Diskussionen.

```
Baseline (ohne Gemini):   Ø 34.5h pro MR bis Merge
Mit Gemini CLI:           Ø 21.2h pro MR bis Merge
Verbesserung:             (34.5 - 21.2) / 34.5 = 38% schneller
```

**Wichtig:** Die Zahl sagt dass eine Verbesserung eingetreten ist — nicht
*warum*. Immer zusammen mit Team-Einschaetzung kommunizieren, nie als
alleinigen Beweis.

---

## Voraussetzungen

- GitLab-Projekt mit MR-History (mindestens 3 Monate vor Gemini-Einfuehrung)
- Bekanntes Einfuehrungsdatum von Gemini CLI im Team
- GitLab-Token mit `read_api`-Berechtigung
- `curl` und `jq` installiert

---

## Option A: GitLab REST API (Free-Tier, pro Repo)

### Schritt 1 — Projektid herausfinden

```bash
export GITLAB_TOKEN="<dein-token>"
export GITLAB_URL="https://gitlab.com"   # oder self-hosted URL

# Projekt-ID anzeigen
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects?search=shop" \
  | jq '.[] | {id: .id, name: .name_with_namespace}'
```

### Schritt 2 — Baseline erheben (MRs vor Gemini-Einfuehrung)

Datum anpassen: bis wann war Gemini noch nicht im Einsatz.

```bash
export PROJECT_ID="<projekt-id>"
export BASELINE_BEFORE="2025-03-01T00:00:00Z"   # Einfuehrungsdatum

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$PROJECT_ID/merge_requests?\
state=merged&created_before=$BASELINE_BEFORE&per_page=100" \
  | jq '[.[] | {id: .iid, created: .created_at, merged: .merged_at}]' \
  > baseline.json

echo "Baseline MRs: $(jq length baseline.json)"
```

### Schritt 3 — Vergleichswert erheben (MRs nach Einfuehrung)

```bash
export GEMINI_AFTER="2025-03-01T00:00:00Z"   # identisches Datum

curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_URL/api/v4/projects/$PROJECT_ID/merge_requests?\
state=merged&created_after=$GEMINI_AFTER&per_page=100" \
  | jq '[.[] | {id: .iid, created: .created_at, merged: .merged_at}]' \
  > with-gemini.json

echo "Mit-Gemini MRs: $(jq length with-gemini.json)"
```

### Schritt 4 — Cycle Time berechnen

```bash
# Durchschnittliche Cycle Time in Stunden
echo "=== Baseline (ohne Gemini) ==="
jq '[.[] | ((.merged | fromdateiso8601) - (.created | fromdateiso8601)) / 3600]
    | add / length | . * 10 | round / 10' baseline.json

echo "=== Mit Gemini CLI ==="
jq '[.[] | ((.merged | fromdateiso8601) - (.created | fromdateiso8601)) / 3600]
    | add / length | . * 10 | round / 10' with-gemini.json
```

### Schritt 5 — Verbesserung berechnen

```bash
BEFORE=$(jq '[.[] | ((.merged | fromdateiso8601) - (.created | fromdateiso8601)) / 3600] | add / length' baseline.json)
AFTER=$(jq '[.[] | ((.merged | fromdateiso8601) - (.created | fromdateiso8601)) / 3600] | add / length' with-gemini.json)

echo "Baseline: ${BEFORE}h"
echo "Mit Gemini: ${AFTER}h"
echo "Verbesserung: $(echo "scale=1; ($BEFORE - $AFTER) / $BEFORE * 100" | bc)%"
```

---

## Option B: GitLab Value Stream Analytics (Premium/Ultimate)

Fuer Kunden mit mehreren Repos (Frontend, Backend, API) gibt es eine
eingebaute Ansicht die alle Repos einer GitLab-Gruppe konsolidiert.

| Variante | GitLab-Tier | Scope |
|---|---|---|
| Project-level VSA | Free | Ein einzelnes Repo |
| Group-level VSA | Premium/Ultimate | Alle Repos einer Gruppe zusammen |

**Aufruf im Browser:**
```
Gruppe → Analytics → Value Stream Analytics
```

Dort "Cycle Time" oder "Lead Time" als Metrik auswaehlen und den
Zeitraum auf Vorher/Nachher der Gemini-Einfuehrung einstellen.
Kein API-Aufruf, keine Scripts noetig.

---

## Option C: Fallback bei Server-Wechsel

Wenn der Kunde den Git-Server gewechselt hat (z.B. GitHub → GitLab),
fehlt unter Umstaenden die alte MR-History fuer die Baseline.

### Szenario 1: Alter MR-Export vorhanden

Falls der alte Server per Tool exportiert wurde (JSON/CSV-Dump):
Baseline aus dem alten Export berechnen (Spalten `created_at`, `merged_at`),
Vergleichswert aus der neuen GitLab API (Option A).

### Szenario 2: Kein MR-Export — Git-Log als Fallback

Git-Commits sind bei jeder Migration erhalten. Approximation der
Cycle Time ueber Merge-Commits:

```bash
# Alle Merge-Commits: Hash, Zeitstempel, Parent-Commits
git log --merges --format="%H %ai %P" > merges.txt

# Zeit zwischen Branch-Abzweig und Merge als Proxy fuer Cycle Time
# Fuer jeden Merge: ersten Commit des gemergten Branch suchen
git log --format="%H %ai" feature-branch..HEAD | tail -1
```

**Einschraenkung:** Weniger praezise als MR-Timestamps da Wartezeiten
(Review, Diskussion ohne neuen Commit) nicht sichtbar sind. Als
Naeherung fuer fehlende Baseline aber valide.

### Szenario 3: Alter Server laeuft noch parallel

Beide APIs abfragen und Daten zusammenfuehren:

```bash
# Alte Instanz (Baseline)
curl --header "PRIVATE-TOKEN: $OLD_TOKEN" \
  "https://old-gitlab.example.com/api/v4/projects/$OLD_ID/merge_requests?..." \
  | jq '...' > baseline.json

# Neue Instanz (Mit Gemini)
curl --header "PRIVATE-TOKEN: $NEW_TOKEN" \
  "https://gitlab.com/api/v4/projects/$NEW_ID/merge_requests?..." \
  | jq '...' > with-gemini.json
```

Dann Schritt 4+5 aus Option A unveraendert ausfuehren.

---

## Entscheidungsbaum

```
Ist GitLab Premium vorhanden und mehrere Repos?
  → Ja:  Value Stream Analytics (Option B), fertig
  → Nein: REST API pro Repo (Option A)

Fehlt die Baseline-History (Server-Wechsel)?
  → Alter Export vorhanden:     Export als Baseline, neue API als Vergleich
  → Kein Export, Server laeuft: beide APIs kombinieren (Szenario 3)
  → Kein Export, Server weg:    Git-Log-Fallback (Szenario 2)
```
