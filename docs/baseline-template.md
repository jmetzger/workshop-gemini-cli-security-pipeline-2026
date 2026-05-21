# Baseline-Messung: Gemini CLI Image

**Datum:** ____________________
**TN / Bearbeiter:** ____________________
**Image:** `ghcr.io/google/gemini-cli:____________________`

---

## 1. CVE-Metriken (Trivy)

Befehl:
```
trivy image --format json ghcr.io/google/gemini-cli:latest \
  | jq '{critical: [.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length,
          high: [.Results[].Vulnerabilities[]? | select(.Severity=="HIGH")] | length,
          medium: [.Results[].Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length,
          packages: [.Results[].Packages[]?] | length}'
```

| Metrik | Ausgangswert | Zielwert | Nach MR #1 | Nach MR #2 | Nach MR #3 |
|---|---|---|---|---|---|
| CVE Critical | | 0 | | | |
| CVE High | | <5 | | | |
| CVE Medium | | <20 | | | |
| Package-Anzahl | | minimieren | | | |
| Image-Groesse (MB) | | minimieren | | | |

---

## 2. CIS Docker Benchmark (Trivy Compliance)

Befehl:
```
trivy image --compliance docker-cis ghcr.io/google/gemini-cli:latest
```

| Metrik | Ausgangswert | Zielwert | Nach MR #1 | Nach MR #2 | Nach MR #3 |
|---|---|---|---|---|---|
| CIS PASS | | | | | |
| CIS FAIL | | | | | |
| CIS Pass-Rate (%) | | >85% | | | |

Kritische FAIL-Findings (Ausgangszustand):

```
(hier eintragen was Trivy meldet)
```

---

## 3. Risk Score (Grype)

Befehl:
```
grype ghcr.io/google/gemini-cli:latest --output json \
  | jq '[.matches[].vulnerability.cvss[]?.metrics.baseScore] | max'
```

| Metrik | Ausgangswert | Zielwert | Nach MR #2 |
|---|---|---|---|
| Grype Max Risk Score (0-10) | | <4.0 | |
| Aktiv ausgenutzte CVEs (KEV) | | 0 | |

---

## 4. Guardrail-Status

Befehl:
```
bash tests/guardrails/run.sh
```

| Guardrail | Ausgangsstatus | Nach Haertung |
|---|---|---|
| Netzwerk geblockt (--network none) | PASS / FAIL | |
| Filesystem read-only | PASS / FAIL | |
| Laeuft nicht als root | PASS / FAIL | |
| Keine gefaehrlichen Capabilities | PASS / FAIL | |
| Tool-Allowlist konfiguriert | JA / NEIN | |

---

## 5. Injection-Resistenz

Befehl:
```
bash tests/injection/run.sh
```

| Test | Ausgangsstatus | Nach Haertung |
|---|---|---|
| INJECT_01 Instruction Override | PASS / FAIL | |
| INJECT_02 Fake System Prompt | PASS / FAIL | |
| INJECT_06 Pfad-Traversal | PASS / FAIL | |
| Gesamt | x/8 PASS | |

---

## 6. Notizen

```
Was war ueberraschend?


Groesste Luecke:


Prioritaet fuer MR #1:

```
