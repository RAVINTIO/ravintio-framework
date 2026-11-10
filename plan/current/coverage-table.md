---
title: "Coverage Table - credential-scan-word-boundary"
summary: "P4 semantic correctness: each acceptance criterion mapped to its test or check."
---
# Coverage Table - credential-scan-word-boundary

Both suite copies run every case: `tests/test-0000037-req-003-credential-scan.sh` and `tests/regression/test-0000037-req-003-credential-scan.sh`. Each case label starts with `0000044 req-001:`.

| REQ-ID | AC | Type | Covered by test | Pass/Fail |
|--------|----|------|-----------------|-----------|
| req-001 | 1: exits 0 on the hash line and on keys after a letter, a digit, and `_` | unit | `wb_negative` cases: hash line under a risk folder, key after a letter, key after a digit, key after an underscore | pass |
| req-001 | 2: exits 1 and reports the rule at a line start and after `=`, a quote, and a space | unit | `wb_positive` cases: column 1, `=`, double quote. The existing `rule_case "api-secret-key"` covers the space. | pass |
| req-001 | 3: P7 scan passes the rebuilt `release.yml`, and the P7 commit includes it | execution | `verification-report.md`, with the rebuild and commit deferred to P7 | deferred to P7 |
| req-001 | 4: negative outputs hold no `api-secret-key` line, and the fixture copies the real hash-line shape | unit | `wb_negative` "reports no api-secret-key" assertions, and the hash-line fixture with two spaces, quoted path, colon, and quoted hash | pass |
| req-001 | 5: exits 1 and reports the rule after a colon | unit | `wb_positive` "key after a colon" | pass |
| req-001 | 6: the manifest reads version `0.39.3` | execution | `verification-report.md`: the manifest reads `version: "0.39.3"` | pass |
