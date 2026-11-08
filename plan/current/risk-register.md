---
title: "Risk Register - fix-windows-shards-pr-77"
summary: "Risks specific to the 0000042 Windows suite fix."
---
# Risk Register - fix-windows-shards-pr-77

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | The four link-case skips hide a real Windows defect in `project-kind.mjs` link handling | low | medium | Linux and macOS still run every link case. Each skip prints its reason. | accepted |
| R-002 | technical | A third Windows failure shows only after P7, and `gate-write` blocks the fix (backlog 0000426) | low | high | P3 pushes the fix and reads the Windows shards before P7 archives the design | open |
| R-003 | operational | The P7 credential scan holds back `release.yml` again (backlog 0000425) | high | low | The `release-copy-integrity` job passes with its skip notice. The final report names the held-back file. | accepted |
| R-004 | technical | The blob compare reads the wrong pack path in the source repo, where `RAVINTIO_PACK_DIR` points at `src/ravintio-framework/` | medium | medium | `git hash-object` reads the working-tree file at `$FW`, so the compare follows the resolver | open |

## Assumptions Logged as Risks

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | Git Bash `ln -s` makes a copy on the Windows runner | The skip hides link coverage that Windows could give | open |
| A-002 | The Windows checkout converts LF to CRLF | The byte compare failed for another reason that still needs a look | open |
| A-003 | Node reads `/tmp/...` inside a `node -e` string as `C:\tmp\...` | The import cases still fail after the `pwd -W` change | open |
