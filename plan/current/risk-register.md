---
title: "Risk Register - credential-scan-word-boundary"
summary: "Feature-specific risks for 0000044."
---
# Risk Register - credential-scan-word-boundary

| ID | Risk | Category | Likelihood | Impact | Mitigation |
|----|------|----------|-----------|--------|-----------|
| R-001 | A real `sk-` key glued to an ASCII letter, a digit, or `_` goes undetected by the regex rule | security | low | medium | Accepted at P0 Scope Lock (error path). The suite pins the cases. gitleaks still runs where it is installed. |
| R-002 | Another `release.yml` line trips a different rule, so P7 still holds `release.yml` back | operational | low | low | The P0 scan of the current `release.yml` showed only the two `api-secret-key` hits. P4 scans the file again with the new rule. |
| R-003 | A suite fixture holds a literal key that matches the rule, so the suite file itself gets held back | operational | medium | low | Each fixture builds its key at run time, as the existing `rule_case` fixtures do. Every commit runs the scan first. |
| R-004 | The two suite copies drift, because a case lands in only one | technical | medium | low | Both copies get the same cases in the same commit. P4 runs both. |
