# Security Report - credential-scan-word-boundary

**Skill:** [security-agent](../../ravintio-framework/skills/ravintio-security-agent/SKILL.md)
**Feature:** 0000044-credential-scan-word-boundary
**Wave:** not waved
**Version:** 0.39.3

> It is advisory - no code changes are made. All findings require human review before action.

## Summary

**Overall Risk Assessment:** medium
**Components Reviewed:** ravintio-framework
**Review Scope:** all (code review, threat model, dependency audit, and secrets handling). No IaC exists in the change set.

The word boundary fixes the `release.yml` false match. It keeps detection for every plain config, env, JSON, YAML, shell, URL, and code context tested. It loses detection where an encoding or an escape puts a letter or a digit directly before the key prefix. Percent-encoding and backslash escapes are the common cases. The old rule caught all of them. This environment and CI run no second scanner, so the regex rule is the only control. The rating is medium for that reason.

Review method:

- Read the whole of `src/ravintio-framework/scripts/credential-scan.mjs` and the diff `ccd598b1..HEAD -- src/`.
- Ran the new pattern and the old pattern against 26 synthetic contexts. Each probe built its key at run time in the scratchpad. No probe text sits in the repository.
- Timed the new pattern on single lines of up to 10 MB.
- Ran `credential-scan.mjs --file` on each changed file. Each exited 0.
- Ran both suite copies. Each reported 189 passed and 0 failed.

## Findings

| ID | Severity | Category | Component | Description | Recommendation | Status |
|----|----------|----------|-----------|-------------|----------------|--------|
| S-001 | medium | data-exposure | ravintio-framework | `src/ravintio-framework/scripts/credential-scan.mjs:57`: the `\b` skips a key prefix after an encoded or escaped delimiter. Each of these contexts now misses, and the old rule matched each one: a percent-encoded `=`, quote, space, or colon (`%3D`, `%22`, `%20`, `%3A`), a JSON or log escape (`\n`, `\t`), and a Unicode escape (`"`). These shapes occur in URL-encoded form bodies, curl and HAR traces, escaped JSON in agent transcripts, and build logs. RAVINTIO commits build logs and plan artifacts, so these shapes can reach a commit. | Accept as a known gap for this patch, or extend the rule in a follow-up. One option is a lookbehind that also accepts a percent-encoded byte or a backslash escape before the prefix, for example `(?:\b\|(?<=%[0-9A-Fa-f]{2})\|(?<=\\[nrt]))` before `sk-`. Add suite cases for `%22`, `%3D`, and `\n`. Record the gap in R-001. | open |
| S-002 | low | config | ravintio-framework | `plan/current/risk-register.md:9` names gitleaks as the fallback for R-001. `credential-scan.mjs:84-87` runs gitleaks only when it is on PATH. It is absent in this environment (the scan printed `scan mode: regex only (gitleaks not found)`). `.github/workflows/ravintio.yml` runs neither the scan nor gitleaks. So the regex rule is the sole control in the paths reviewed, and the fallback doesn't reduce R-001 there. | Restate the R-001 mitigation so it doesn't count on gitleaks. Optionally install gitleaks in CI, or document that the regex rule is the only scan in a default install. | open |
| S-003 | low | data-exposure | ravintio-framework | `credential-scan.mjs:57`: the boundary also skips a prefix glued to a word character, such as `TOKEN_` or `KEY` with no separator, or a hex or base64 run. Probes confirmed each one now misses. Provider keys in configs and env files rarely sit like this. ADR-002 and the P0 Scope Lock accept the trade. | None beyond S-001. The trade is accepted and the suite pins it at `tests/test-0000037-req-003-credential-scan.sh:200-202`. | accepted |
| S-004 | informational | data-exposure | ravintio-framework | `credential-scan.mjs:57`: no rule matches the secret-key format that uses an underscore after `sk`, the `sk_live_` style. This gap predates this change and lies outside its scope. | File a backlog entry to weigh an underscore variant against its false-match cost. | open |
| S-005 | informational | config | ravintio-framework | `credential-scan.mjs:57`: the pattern stays linear on one long line. It holds a literal prefix, a zero-width `\b`, and one bounded class with no nested quantifier. On adversarial 10 MB lines, made of repeated short prefix runs and runs one character under the floor, it took about 15 ms. The old pattern behaves the same. | None. | mitigated |
| S-006 | informational | data-exposure | ravintio-framework | The scan still never prints matched text. Reports print only `safePath(path)`, the line, and the rule (`credential-scan.mjs:225` and `credential-scan.mjs:299`). The change doesn't touch output. Each new positive case asserts the output lacks the key (`tests/test-0000037-req-003-credential-scan.sh:197`). | None. | mitigated |
| S-007 | informational | data-exposure | ravintio-framework | The suite fixtures hold no matching text. The key, the hash, and the folder name are each built at run time from split literals (`tests/test-0000037-req-003-credential-scan.sh:179-181`, same lines in the regression copy). `credential-scan.mjs --file` exits 0 on `credential-scan.mjs`, both suite copies, and `component.yml`. | None. | mitigated |

Coverage kept by the new rule, from the probes:

| Context | Old rule | New rule |
|---------|----------|----------|
| env file `KEY=` value | match | match |
| shell `export` with a quoted value | match | match |
| YAML value, bare or quoted | match | match |
| JSON string value | match | match |
| URL query value and URL userinfo | match | match |
| `Authorization: Bearer` header | match | match |
| code call with a quoted argument | match | match |
| backtick, tab, HTML entity, non-ASCII letter before the key | match | match |
| percent-encoded delimiter before the key | match | miss (S-001) |
| backslash or Unicode escape before the key | match | miss (S-001) |
| letter, digit, or `_` glued before the key | match | miss (S-003, accepted) |

## Risk register cross-reference

| Risk | Status in the implementation |
|------|------------------------------|
| R-001 | Open and wider than recorded. The register names a key glued to a letter, a digit, or `_`. The realistic cases are encoded or escaped delimiters (S-001). The gitleaks mitigation doesn't apply where gitleaks is absent (S-002). |
| R-002 | Mitigated. `credential-scan.mjs --file ravintio-framework/release.yml` exits 0 on the current untracked `release.yml`. |
| R-003 | Mitigated. See S-007. |
| R-004 | Mitigated. The two suite copies differ only in the helper path (line 15) and the pack path (line 17). The new cases sit at lines 177-206 in both. Both copies pass. |

## Dependency Audit

| Package | Current Version | Known CVEs | Severity | Action Required |
|---------|----------------|------------|----------|----------------|
| Node built-ins only (`node:child_process`, `node:fs`, `node:os`, `node:path`) | runtime Node | none | low | accept-risk |
| gitleaks (optional, external, not installed here) | not present | not assessed | low | accept-risk |

The change adds no dependency.

## Threat Model

| Threat | Attack Vector | Affected Component | Likelihood | Impact | Existing Mitigation | Gap |
|--------|--------------|-------------------|------------|--------|--------------------|----|
| Information disclosure: a real key in an encoded or escaped context reaches a commit or a PR body | A build log, transcript, or trace holds a percent-encoded or backslash-escaped key, and the scan passes it | ravintio-framework | medium | medium | Plain contexts still match. gitleaks runs where it is installed. | No coverage for `%XX` or `\n`-style prefixes, and no gitleaks in CI (S-001, S-002) |
| Information disclosure: a key glued to a word character passes | An identifier or a blob runs directly into the key | ravintio-framework | low | medium | Accepted at P0 Scope Lock. The suite pins the cases. | Accepted (S-003) |
| Information disclosure: the scan prints the secret it finds | A report line echoes the matched value | ravintio-framework | low | high | Reports print path, line, and rule only. Suite assertions check this. | None (S-006) |
| Denial of service: one long line stalls the scan | A large minified or generated file | ravintio-framework | low | low | Linear pattern | None (S-005) |
| Tampering: an agent edits a held-back file to hide a match | An agent rewrites `release.yml` | ravintio-framework | low | medium | Design constraint and 0000041 ADR 004. The release script writes `release.yml`. | None in this change |

## Recommendations

Ordered by priority:

1. Record the encoded and escaped delimiter gap in R-001, and decide whether to extend the rule with a lookbehind for `%XX` and backslash escapes (S-001).
2. Restate the R-001 mitigation so it doesn't count on gitleaks, or install gitleaks in CI (S-002).
3. File a backlog entry for the underscore form of the secret-key prefix (S-004).
