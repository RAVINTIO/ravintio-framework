---
title: "Backlog Entry: 0000360 - a report skill for a scope of work or a strategy"
summary: "Turn the hand-built regulated strategy review into a Framework-owned skill that writes a controlled, illustrated PDF report from a scope of work or a strategy."
status: "open"
---
# Backlog Entry: 0000360 - a report skill for a scope of work or a strategy

**Source feature:** none (human request)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000286, 0000289, 0000301, 0000302, 0000355

---

## Problem

On 2026-10-31 the agent wrote `plan/reports/2026-10-31-regulated-strategy-review.pdf` without a skill. It wrote the HTML, CSS, and inline SVG diagrams by hand and printed them to PDF with headless Chrome. The owner wants a repeatable skill that writes this kind of report. They also plan to port it to RAVINTIO Zero for its initiatives.

The hand-built run exposed these gaps:

- **No template.** Layout, the palette, the document-control block, and the page header and footer came from scratch. A second report would drift from the first.
- **No sanctioned writer.** Chrome wrote the PDF straight into `plan/reports/`. That breaks boot Hard Limit 8, which allows only Write, Edit, and listed scripts to change project files.
- **Fonts broke copied text.** Google Fonts serves variable fonts. Chrome embedded them as Type 3, so copied text split at some letters. Rev 1.1 moved to static fonts, but the page header still uses one Type 3 font.
- **Network at render time.** The page loads fonts from a CDN when Chrome renders it. An offline or locked-down machine renders with fallback fonts.
- **Manual layout checks.** The agent found a spilled cover, an orphaned heading, and overlapping labels only by viewing rendered pages one by one.
- **No source binding.** Nothing ties each claim in the report to the backlog entry or file it came from. A reader can't tell when the report goes stale.

## Suggested Action

Build a Framework-owned skill, for example `ravintio-report`. It isn't a bundled third-party skill, so 0000301 doesn't remove it. It should do these things:

1. **Take a scope.** Accept a scope of work, such as a set of backlog entries, a feature, or a strategy record like 0000355. For Zero, accept an initiative.
2. **Use a fixed structure.** Cover with headline figures, document control, summary, sections, decisions for the owner, delivery order, and an appendix index of sources.
3. **Use templates.** Ship an HTML and CSS template with the palette, page furniture, and figure styles in `ravintio-framework/templates/`. Teams restyle it through `ravintio-overrides/`.
4. **Draw diagrams from data.** Provide figure patterns for a pipeline, a flow with decisions, a lifecycle, a matrix, and a bar chart. The agent fills them from structured data rather than hand-placing coordinates.
5. **Embed fonts locally.** Ship static font files with an open licence in the pack, so rendering needs no network and every font embeds as TrueType.
6. **Render through a sanctioned script.** Add a script such as `ravintio-framework/scripts/render-report.mjs` and add it to the Hard Limit 8 list. It writes the PDF next to its HTML source.
7. **Check the output.** The script fails on a Type 3 font, a missing page count, an empty page, or text that runs past its box. It writes page images for the agent to review.
8. **Bind sources.** Each claim cites an entry ID or file path. The appendix lists each source with its commit. A later run reports which sources changed since the report.
9. **Control revisions.** Each report has a document ID and a revision. A change bumps the revision and logs it. Approval comes through 0000286 when a regulated profile is active.
10. **Follow the writing standard.** The prose follows the project writing rules and 0000328.

## Wanted outcome

- One command turns a scope into an HTML source and a PDF with a consistent look.
- Rendering works offline and embeds no Type 3 font.
- Copied text from any page matches the source text.
- Every claim traces to a cited entry or file.
- The same skill runs in Zero against an initiative, with only the scope input changed.

## Open questions

- Should Framework and Zero share one skill source, or should each keep its own copy?
- Should the skill require Chrome, or ship a render engine that needs no browser?
- Which font families and licences fit the pack?
- Should reports live in `plan/reports/` or in an archive folder per scope?

## Why Deferred

The owner asked for it on 2026-10-31, during the Zero review on a chore branch. It needs its own design, a new sanctioned script, and changes to the Hard Limit 8 list.
