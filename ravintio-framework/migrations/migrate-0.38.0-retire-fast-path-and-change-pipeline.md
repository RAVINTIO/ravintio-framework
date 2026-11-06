# Migration: retire Fast Path and the Change Pipeline for 0.38.0

**Target:** every project, the framework source included.
**Scope:** `plan/.fast-path-scope` and `.github/workflows/ravintio.yml`. The migration also reads `plan/current/` for an unfinished run, and changes nothing there. It never edits `docs/` or application code.
**May edit:** `.github/workflows/ravintio.yml`
**Safe to skip:** No. A consumer's old CI file keeps the Fast Path exemption until this migration runs.

---

## Background

Framework version 0.38.0 (feature `0000040-retire-fast-path`) retires Fast Path and the Change Pipeline. Every change now runs the Feature Pipeline.

Two leftovers can stay in a consumer repo after the upgrade:

- `plan/.fast-path-scope`, the scope record that a Fast Path run left. From 0.38.0 no gate reads it, so it admits nothing. It is still stale, so this migration asks the human on the loop to delete it.
- the Fast Path exemption block in `.github/workflows/ravintio.yml`. Setup in 0.37.x shipped it. It lets a branch whose commits all use the `fix(fast-path):` subject pass `validate-branch` with no feature record.

Setup copies the CI template only when the CI file is absent. So a setup re-run never removes the block, and this migration does. It removes the block and nothing else. Your CI file keeps its old `src/` check. It doesn't gain the source folder rule that 0.38.0 adds to the template. To take that rule, compare your file with `ravintio-framework/hooks/ravintio.yml`. Backlog 0000364 covers this gap.

This migration names the CI file on its `**May edit:**` line, so the migrator may edit it (ADR-006). The human on the loop confirms that edit on its own.

In the framework source, feature 0000040 has already removed the block, and no scope record exists. So the migration finds nothing there and records `applied` with both counts at `0`.

---

## The exemption block

Setup in 0.37.x shipped this block, quoted here verbatim. It runs from the `# Fast Path exemption:` comment to the `fi` that closes the `FAST_PATH_COUNT` test.

```yaml
          # Fast Path exemption: if all commits are fix(fast-path): only require component.yml or changelog
          FAST_PATH_COUNT=$(echo "$COMMIT_MESSAGES" | grep -cE "^fix\(fast-path\):" || true)
          TOTAL_COUNT=$(echo "$COMMIT_MESSAGES" | grep -c "." || true)

          if [ "$FAST_PATH_COUNT" -gt 0 ] && [ "$FAST_PATH_COUNT" -eq "$TOTAL_COUNT" ]; then
            if echo "$CHANGED_FILES" | grep -q "^src/"; then
              if ! echo "$CHANGED_FILES" | grep -qE "(component\.yml|plan/changelog/)"; then
                echo "::error title=RAVINTIO Fast Path Violation::Fast Path commits must update component.yml or plan/changelog/."
                exit 1
              fi
            fi
            echo "✅ RAVINTIO fast-path pipeline passed."
            exit 0
          fi
```

The block holds 14 lines, the blank line included. Leading spaces count in the match. Trailing whitespace doesn't.

---

## Migrator Instructions

Run these steps in order. Every step is safe to repeat. A deleted scope record, a removed block, and an absent CI file each count as done. An interrupted run applies again cleanly, and a second full run changes no file.

1. Confirm that `ravintio-framework/component.yml` reports version `0.38.0` or later. If it's older, stop and ask the human on the loop to refresh `ravintio-framework/` first. Record nothing, so the migration stays pending.
2. Check `plan/current/` for an unfinished run of a retired track:
   - A Fast Path run leaves `plan/.fast-path-scope`.
   - A Change Pipeline run leaves `plan/current/change-summary.md`.

   If either file exists, warn the human on the loop that the track is gone. Tell them to restart the work on the Feature Pipeline. The warning changes no file.
3. If `plan/.fast-path-scope` exists, ask the human on the loop to delete it. The migrator never deletes it itself, because the Write-or-Edit rule (boot Hard Limit 8) names no delete route (backlog 0000366). Show them this command, to run from the project root:

   `rm -- plan/.fast-path-scope`

   In Claude Code they can type `! rm -- plan/.fast-path-scope`. If the path is a symbolic link, `rm` removes the link and never its target. When they say it's done, check that the path is gone, as a file or as a link. If the path still exists, the record body names `plan/.fast-path-scope`. The outcome doesn't change, because no gate reads the file. If the path doesn't exist, this step is done.
4. Read `.github/workflows/ravintio.yml`. If the file doesn't exist, steps 4 and 5 are done. Otherwise look for the block in `## The exemption block`. Trim trailing whitespace from each line on both sides, then compare. Count each place where all 14 block lines match in a row.
5. If the block matches once, show its lines with their line numbers. Ask the human on the loop to confirm the removal. This edit needs its own confirmation, and a batch `all` answer doesn't cover it. In `autonomous` run mode the migrator still asks, because the edit changes a file the consumer owns. On confirmation, remove those 14 lines with the **Edit** tool and nothing else. Every other line stays byte-identical. Count the edit in `corrections-applied`.

   If the block matches nowhere and the file holds neither `fix\(fast-path\)` nor `FAST_PATH_COUNT`, the block is already gone. This step is done.

   The file may hold `fix\(fast-path\)` or `FAST_PATH_COUNT` while the block doesn't match once. That reason is `no match`. If the human on the loop declines the removal, the reason is `declined`. In both cases the migrator edits nothing in the CI file, and it does these things:
   - It names the file and the line numbers to delete by hand. For `no match`, it names each line that holds `fix(fast-path)`, `fix\(fast-path\)`, or `FAST_PATH_COUNT`.
   - It counts the edit in `corrections-skipped`.
   - It records the outcome `skipped`. The record body names the reason as `declined` or `no match`.
   - It never records `applied` with `corrections-skipped: 0` for this case.
6. Tell the human on the loop that Fast Path and the Change Pipeline are gone. Every change now runs the Feature Pipeline. Ask for a setup re-run for each tool the project uses. Use `ravintio-framework/setup.sh` or `setup.ps1` with the flags the project normally uses. The re-run removes the installed copies of the retired track files. Also say that the CI file keeps its old `src/` check. Name `ravintio-framework/hooks/ravintio.yml` as the template to compare against (backlog 0000364).
7. Record the outcome, as `## Record` describes. Set it from these rules:
   - `skipped` when step 5 found `declined` or `no match`.
   - `applied` in every other case where steps 1 to 6 ran. A run that found nothing records `applied` with both counts at `0`.
   - The counts cover the CI edit only. The human on the loop runs the scope record delete, so no count includes it.

---

## Present Findings

Report to the human on the loop:
- the version that `ravintio-framework/component.yml` reports
- each unfinished-run leftover found in step 2, with the warning
- whether `plan/.fast-path-scope` existed, and whether it is gone after step 3
- the CI file result: the block removed, already gone, the file absent, `declined`, or `no match`
- for `declined` or `no match`, the file and the line numbers to delete by hand
- the setup re-run request, with each tool the project uses
- the reminder that the CI file keeps its old `src/` check, with the template to compare against

---

## Record

Once the human on the loop confirms the findings, the migrator records the outcome at `plan/_migrations/migrate-0.38.0-retire-fast-path-and-change-pipeline.md`. The body states the CI file result. It names `plan/.fast-path-scope` when that path still exists, and it names the reason for a `skipped` outcome. If step 1 stops the run, the migrator records nothing, so the migration stays pending. This file stays where it is.
