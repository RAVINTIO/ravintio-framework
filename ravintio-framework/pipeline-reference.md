# Pipeline Reference

> Deep reference for RAVINTIO Framework pipeline mechanics. For first-time setup, start with [getting-started.md](getting-started.md).

---

## Phase Indicators

Every agent response begins with a phase prefix. You always know where you are.

| Prefix | Phase | What the agent is doing |
|--------|-------|-------------------------|
| `P0:` | Assess & Coach | Reviewing the brief; asking gap questions; confirming per-phase review, continuous run, or autonomous run |
| `P1:` | Spec | Writing requirements, scope, glossary, risk register |
| `P2:` | ADRs | Documenting architecture decisions |
| `P3:` | Codegen | Generating implementation |
| `P4:` | Validate | Running CI checks; self-correcting |
| `P5:` | Security | Security review; STRIDE threat model |
| `P6:` | Docs | Documentation artifacts; drift checks |
| `P7:` | Archive | Changelog, skips, `product.yml` release fields, archive plan/current/, regression confirmation, test report |
| `P8:` | Build Assessment | Efficiency audit: model routing, parallelism, self-corrections (sub-agent of ship-agent) |
| `P9:` | Ship | Git tag, push/PR decision, PR raised or PR description output |

Standard response formats:
- Entering a phase: `Px: Starting — {one-liner}`
- Resuming: `Px: Resuming — {what was in progress, what is next}`
- Completing: `Px: Complete — {one-liner summary}`
- Blocked: `P0: Blocked — {specific gap}`
- Skipped: `Px: Skipped — {reason}`

If you see `Px: Resuming…` at the start of a session, the orchestrator detected existing artifacts in `plan/current/` and is continuing where it left off.

---

## Phase Confirmation Gates

At the end of each phase, the orchestrator **stops and presents a summary** before proceeding. Before the pipeline begins (end of P0), you are asked:

```
How should the agent run this session?

  [1] Interactive: the agent stops for you at every phase gate
  [2] Continuous: the agent runs P1 to P6 without stopping for you
  [3] Autonomous: the agent runs from the confirmed design to a raised PR, and stops for you only on exception-list items
```

In an autonomous run, only exception-list items wait for you. See [autonomous-run-standards.md](standards/autonomous-run-standards.md).

Per-phase exceptions — the orchestrator may skip the stop if **both** conditions are true:
- You chose continuous run, AND
- There is genuinely nothing to check (e.g. P5 with zero security findings, P4 with all checks passing first attempt)

**P9 always stops.** Raising a PR is an external action — it is never auto-confirmed, even in continuous run mode.
In an `autonomous` run, the agent raises the PR and ends with the final report, and the human on the loop still merges.

---

## Phase 8 — Build Assessment

P8 runs automatically after P7 archives the plan. The ship-agent spawns the `ravintio-build-assessment-agent` as a sub-agent, passing the archive path. The agent reads the archived `build-log.md` and produces a structured efficiency report at `plan/_archive/{feature-id}-{date}/build-report.md`. Once P8 completes, the ship-agent proceeds to P9.

## Phase 9 — Ship

P9 is the terminal phase. The ship-agent reads the version, creates a local git tag (`v{version}`), then asks the human whether to push and raise the PR or output a PR description for manual use. If `local-git-only` is active in `ravintio-overrides/instructions/`, the agent skips the prompt and outputs a PR description directly.

P9 takes the version from `product.yml` through `product-version.mjs`. With no `product.yml` and one component, it reads that `component.yml` instead. P9 never edits `product.yml`. P7 sets its `version` and `feature` through `set-product-release.mjs`, a sanctioned script under the Write-or-Edit rule (boot Hard Limit 8). In a project with two or more components and no `product.yml`, P7 creates the file with `--create`.

### Build Log

From P0 onwards, the orchestrator maintains `plan/current/build-log.md` — a working file tracking per-phase progress. It is created from `ravintio-framework/templates/build-log.template.md` at P0 and appended at each phase boundary. If a session is interrupted and resumed, the orchestrator appends rather than overwrites.

The build log records per phase: model tier used, skills loaded, agents spawned, MCP tool calls, parallel task batch count.

### What the P8 audit checks

P8 is adversarial, not a summary. It asks:

- **Model routing**: which phases used the primary tier when cheaper-tier tasks were eligible?
- **Parallelism**: which phases ran tasks sequentially that should have been parallel?
- **Phase gates**: were human confirmation gates honoured, or did the pipeline run autonomously without authorisation?
- **Self-corrections**: how many occurred, and were they avoidable?
- **Build log integrity**: are all phases represented with populated fields?

---

## Model Tier Routing

The orchestrator consults the **Model Tier Decision Table** before spawning every subagent, then passes the resolved model explicitly.

| Task type | Tier |
|-----------|------|
| Codebase discovery (grep, find, ls) | Cheaper |
| Single-file read with no synthesis | Cheaper |
| Formatting / spelling / lint checks | Cheaper |
| Validation (lint, typecheck, test runner) | Cheaper |
| Fetching a single known reference doc | Cheaper |
| Documentation writing (no novel decisions) | Cheaper |
| Web research with synthesis | Primary |
| Code generation | Primary |
| Security review | Primary |
| ADR writing | Primary |
| Spec / requirements writing | Primary |
| Phase 0 coaching | Primary |
| Build assessment (P8) | Cheaper |

**Tier-to-model mapping** (current as of May 2026):

| Tool | Primary | Cheaper |
|------|---------|---------|
| Claude Code | sonnet | haiku |
| Cursor | gpt-4o | gpt-4o-mini |
| Codex | o1 | o1-mini |
| GitHub Copilot | gpt-4o | gpt-4o-mini |
| Windsurf | claude-sonnet-4-6 | claude-haiku-4-5 |

---

## One track: the Feature Pipeline

Every change runs the Feature Pipeline, from P0 to P9. That covers these changes:

- a bug fix or a copy change
- a change to an existing feature
- a change with no `src/` target, such as a documentation, governance, or tooling change

No lighter route skips a phase or its record.

The orchestrator triages each request before it acts. Triage has two outcomes:

- A request that meets a standalone skill trigger invokes that skill. The standalone skills are `ravintio-optimise-agent`, `ravintio-refresh-setup`, and the retrofit workflow.
- Every other request goes to the Feature Pipeline.

The version bump follows the run. A Feature Pipeline run takes a minor bump, and a breaking change takes a major bump. The human on the loop confirms the version at P0.

---

## Git Guardrails

The setup script activates RAVINTIO's **Progressive Guardrail System** — a three-tier enforcement model that protects `main` without blocking atomic commits.

| Tier | When | What happens |
|------|------|--------------|
| **1 — Advisory pre-commit** | Every local commit | Checks whether code was staged without docs. Prints a warning if so. Commit **succeeds** regardless. |
| **2 — Branch pre-push** | Every `git push` | Checks the cumulative branch diff. Push **fails** if the diff touches a source folder with no file under `plan/` or `docs/`. |
| **3 — CI/CD pipeline** | Every Pull Request | Same check in GitHub Actions. Blocks the merge button if the rule is violated. |

### Source folder rule

Tier 2 and Tier 3 apply one source folder rule (0000040 ADR-003). No commit subject relaxes it.

A source folder is one of these:

- `src/`, which always counts
- the folder of each `component.yml` that `product.yml` lists

The rule reads `product.yml` from the base commit and from `HEAD`, and takes the union of both lists. A branch that drops a component from `product.yml` still has that folder checked. The rule never scans the tree for `component.yml` files.

A record is a file under the top-level `plan/` or `docs/` folder. A `component.yml` counts as source, not as a record. If the diff touches a source folder, the same diff must touch a record.

| Case | What happens |
|------|--------------|
| The base commit can't be resolved, as in a shallow clone | The check fails closed. The message names `fetch-depth: 0`. |
| Pre-push finds no `origin/main` ref | Pre-push checks nothing and prints a warning. CI still runs the rule on the pull request. |
| `product.yml` is absent | Only `src/` is checked. |
| `product.yml` is unreadable, or lists no component the rule can read | Only `src/` is checked, with a warning that names the file. |

### Hook file locations

| File | Purpose |
|------|---------|
| `ravintio-framework/hooks/pre-commit` | Tier 1 advisory check |
| `ravintio-framework/hooks/pre-push` | Tier 2 blocking check |
| `.github/workflows/ravintio.yml` | Tier 3 CI check (copied to repo on first setup) |

Hooks are wired via `git config core.hooksPath ravintio-framework/hooks` — no `.git/` directory modifications required. This means hooks travel with the repo and apply to every contributor who has run `setup.sh`.

### What happens on a Tier 2 violation

```
❌ RAVINTIO ENFORCEMENT FAILED: Push Rejected.
----------------------------------------------------------------
Your branch changes these source folders, but no file under
plan/ or docs/ was also touched in this diff:
  - src/
A component.yml counts as source, not as a record.
This is a presence check, not a correspondence guarantee. It
does not verify the content actually matches your change.
You cannot push this branch until you commit updates to:
  - plan/ (current or archived feature docs)
  - docs/ (living documentation)
----------------------------------------------------------------
```

To fix it, update `plan/` or `docs/` to record the change, then push again.

---

## Orchestrator Sentinel

### Lifecycle

When Phase 0 starts, the orchestrator writes `plan/.orchestrator-active` containing the active feature-id (e.g. `0000002-doc-structure`). This file is the sentinel — its presence signals that a pipeline run is in progress. It is deleted **last** at Phase 7, after the archive is confirmed complete.

```
P0 start     → plan/.orchestrator-active written (contains "pending" until feature-id confirmed)
P0 complete  → plan/.orchestrator-active updated with confirmed feature-id
P1–P6        → sentinel present; hooks enforce scope on every turn
P7 complete  → plan/.orchestrator-active deleted (final cleanup step)
```

### Three enforcement hooks

| Hook | Trigger | What it does |
|------|---------|-------------|
| **gate-write** (PreToolUse: Write, Edit) | Every file write or edit | Blocks writes outside always-permitted paths (`plan/`, `docs/`, and named files such as `CLAUDE.md`) unless `plan/current/design.md` exists AND the target path matches a declared component in the design. With no design, the gate blocks every write outside `plan/`, `docs/`, and the always-permitted names |
| **check-orchestrator-presence** (UserPromptSubmit) | Every user prompt while sentinel is present | Injects a reminder banner so the orchestrator skill reloads after context compaction or session resume. Advisory by default — see Strict Mode below |
| **check-design** (UserPromptSubmit) | Every user prompt | If neither the sentinel nor a `feature-brief.md` is present, injects a hard STOP message before the agent can act. Prevents free-form changes outside the pipeline |

### How gate-write interacts with design.md

`gate-write` checks two conditions before allowing a write to `src/`:

1. `plan/current/design.md` must exist
2. The target file path must be under a component directory declared in the design's `## Engineering Layer → Components` section

Writes to `plan/` and `docs/` are always permitted. So are named files such as `CLAUDE.md`, `AGENTS.md`, `.gitignore`, and `pause.md`, wherever they sit. `gate-write` never blocks documentation or plan artifact writes. Other paths, `ravintio-framework/` and `ravintio-overrides/` included, need a design that lists them. An always-permitted name inside a path that `ENFORCEMENT_PATHS` lists gets no shortcut, so it takes the normal route. `ENFORCEMENT_PATHS` in `path-rules.mjs` covers the hook folders, hook wiring, tool-local settings, setup scripts, the CI workflow, and `.git/`.

### How the gates judge a path

`gate-write`, the shell-write guard, and `ratchet-check` share the path rules in `hooks/enforcement/path-rules.mjs`.

- **Links and `..`:** A gate follows each symbolic link to its real target and judges that target, not the link path. `gate-write` also judges `..` as text, as the **Write** tool places it, and blocks if either placement blocks. The shell-write guard judges the physical path only, as the kernel resolves it.
- **Fail-closed line:** A link loop, a chain past 40 links, or another resolution error blocks with exit 2 when the target lies inside the root. The reason names the cause on stderr. A target outside the root passes.
- **Deleted working folder:** If the working folder no longer exists, the gates find the root from `CLAUDE_PROJECT_DIR` first. Without it, they walk up to the nearest existing parent.
- **Planted root markers:** A `.git` or `ravintio-framework/` marker never makes a root when it sits below `plan/`, `docs/`, or an always-permitted name such as `claude.md`. The walk goes on to the next trusted marker above it.
- **Subfolders:** `ratchet-check` uses the same root lookup, so it guards `plan/current/` artifacts from any project subfolder.

### Manual recovery

If a pipeline run is interrupted and you want to start fresh:

```bash
# 1. Delete the sentinel
rm plan/.orchestrator-active

# 2. Delete the active feature brief
rm plan/current/feature-brief.md

# 3. Optionally clear the current plan artifacts
rm -rf plan/current/

# 4. Reload the orchestrator in your tool — it will begin a fresh P0
```

Do not delete `plan/_archive/` or `plan/changelog/` — these are historical records.

---

## Strict Orchestrator Mode

By default, `check-orchestrator-presence` is advisory — it injects a reminder banner but never blocks the session. Strict mode turns this into a hard gate.

### How it works

Enable strict mode at setup time:

```bash
# macOS / Linux
./ravintio-framework/setup.sh claude-code --strict-orchestrator
```

```powershell
# Windows (PowerShell)
.\ravintio-framework\setup.ps1 claude-code --strict-orchestrator
```

This writes `plan/.orchestrator-strict`. When that file is present, `check-orchestrator-presence` changes behaviour:

1. **On every new session** — injects a hard-block banner that prevents the agent from acting until the orchestrator skill loads
2. **When the orchestrator loads** — it reads the `session_id` from the banner (injected by the hook) and writes it to `plan/.orchestrator-ack`
3. **On subsequent prompts in the same session** — the hook reads `plan/.orchestrator-ack`, sees the current session_id matches, and passes silently
4. **At Phase 7** — the ship-agent deletes `plan/.orchestrator-ack` so the next session starts clean

### The ack file

`plan/.orchestrator-ack` contains either:
- The `session_id` value injected by the hook banner (if available in the prompt context), or
- The current UTC timestamp in ISO 8601 format (fallback when no session_id is present)

The hook compares the stored value against the current session to determine whether the orchestrator has loaded in this session. The ack file is session-scoped — one value per pipeline session.

---

## Retrofit an Existing Project

### Setup steps

1. Copy `ravintio-framework/` into your repo root
2. Run the setup script for your tool (see [getting-started.md](getting-started.md#3-run-the-setup-script))
3. Add a `component.yml` manifest to each existing component in `src/` — use the [component manifest template](templates/component.template.yml) and [guide](templates/component-guide.md)
4. Tell the orchestrator to use **retrofit** adoption mode:

```
Execute the confirmed design Agentic Iteration Loop in retrofit mode.
Feature brief: plan/current/feature-brief.md
```

### Orchestrator discovery protocol

In retrofit mode, the orchestrator runs a structured discovery pass **before** Phase 0 coaching. It scans the codebase and presents a discovery summary to the human. This reduces the coaching questions required — many answers are already in the code.

**Entry point scan** — the orchestrator looks for:

| File | Reveals |
|------|---------|
| `package.json`, `package-lock.json` | Node.js stack, dependencies, scripts |
| `go.mod`, `go.sum` | Go stack, module path |
| `requirements.txt`, `pyproject.toml`, `setup.py` | Python stack, dependencies |
| `Cargo.toml` | Rust stack |
| `Makefile` | Build targets, environment configuration |
| `Dockerfile`, `docker-compose.yml` | Compute model, service topology |
| `.github/workflows/*.yml` | CI configuration, deployment triggers |

**Component identification** — each directory with its own build or test configuration is a candidate component. The orchestrator creates a draft `component.yml` for each.

**Data ownership mapping** — the orchestrator scans for:
- Database connection strings and ORM configuration files
- Migration directories (`migrations/`, `db/migrate/`, `alembic/versions/`)
- Schema definition files (`.prisma`, `schema.sql`, `models.py`)

Each database or schema maps to exactly one component as owner.

**API contract discovery** — the orchestrator scans for:
- Route definitions (Express routers, Gin route groups, FastAPI decorators)
- Controller/handler files
- gRPC `.proto` files
- Existing OpenAPI specs (`openapi.yaml`, `swagger.json`)

It drafts an OpenAPI spec from what exists, flagging gaps.

**Pattern detection** — the orchestrator identifies existing conventions the pipeline must preserve:
- Auth middleware (must not be duplicated or replaced by new code)
- Logging strategy (must be consistent across new components)
- Error handling patterns (new code must follow the established shape)
- Testing framework and test structure (new tests must use the same framework)

**Tech debt surfacing** — the orchestrator flags:
- Inconsistencies between components (different logging, different error shapes)
- Missing tests for existing logic
- Deprecated dependencies
- Security concerns (hardcoded secrets, missing validation)

These are recorded in the risk register as pre-existing risks, not introduced by the new feature.

### Discovery summary

After the scan, the orchestrator presents a summary before coaching:

```
Retrofit discovery complete.

Components found: {n}
  - {component-name}: {one-line responsibility}
  ...

Data ownership:
  - {database/table}: owned by {component}
  ...

Existing patterns (must be preserved):
  - Auth: {strategy}
  - Logging: {approach}
  - Testing: {framework}

Tech debt flagged: {n} items (see risk register)

Proceeding to Phase 0 coaching — {x} of {y} questions pre-answered by discovery.
```

---

## Updating the Framework

"Updating the framework" means pulling new files into `ravintio-framework/` (via git pull, a submodule update, or copying from the source repo) and then re-running the setup script to propagate the changes.

### Re-run setup after update

Pass the same flags you used during initial setup. Re-running is idempotent — it overwrites generated copies but never touches `ravintio-overrides/`.

```bash
# macOS / Linux — basic
./ravintio-framework/setup.sh claude-code
```

```powershell
# Windows (PowerShell) — basic
.\ravintio-framework\setup.ps1 claude-code
```

### Check for pending migrations

After pulling a new version of `ravintio-framework/`, check for pending migrations before starting a new pipeline run.

Each top-level `*.md` file in `ravintio-framework/migrations/` is a migration. Migration files never move. Each project records its own runs at `plan/_migrations/{stem}.md`, where `{stem}` is the file name without `.md`. A migration is pending when it has no readable record there.

List the migrations and the records side by side:

```bash
ls ravintio-framework/migrations/*.md 2>/dev/null
ls plan/_migrations/*.md 2>/dev/null
```

```powershell
Get-ChildItem ravintio-framework/migrations/*.md
Get-ChildItem plan/_migrations/*.md -ErrorAction SilentlyContinue
```

A record is readable when its YAML frontmatter parses and holds three fields:

- `migration` equals `{stem}.md`
- `outcome` is `applied`, `not applicable`, or `skipped`
- `date` is `YYYY-MM-DD`

The orchestrator detects pending migrations at session start and invokes `ravintio-migrator` before any pipeline work. You don't need to run migrations by hand. The migrator writes each record, and P7 never archives `plan/_migrations/`.

---

## What to Commit

| Path | Commit? | Why |
|------|:-------:|-----|
| `ravintio-framework/` | ✅ | Source of truth — shared with the whole team |
| `ravintio-framework/hooks/` | ✅ | Git hooks and CI workflow — applied by setup scripts |
| `.github/workflows/ravintio.yml` | ✅ | CI/CD gate — must be committed to take effect in GitHub Actions |
| `plan/` | ✅ | Feature briefs, execution plans, ADRs, scope docs — design history |
| `src/` | ✅ | Component code and manifests |
| `docs/` | ✅ | Repo-wide registry and dependency graph |
| `ravintio-overrides/` | ✅ | Team customisations — must be committed to share with the team |
| `.claude/` | Optional | Generated copies — can be `.gitignore`d and regenerated by `setup.sh` |
| `.cursor/` | Optional | Same as above — tool-specific |
| `.agents/`, `.gemini/`, `.github/skills/` | Optional | Same as above — tool-specific |
| `CLAUDE.md`, `AGENTS.md` | Optional | Boot files — regenerated by setup; commit if you want them in the repo for contributors |

### When to commit plan/

Commit `plan/current/` artifacts throughout the pipeline run — not just at P7. Each phase produces artifacts (design, requirements, ADRs, execution plan) that are worth preserving in git history as they are written. On a feature branch this is low risk and provides a clear record of how the design evolved. P7 archives the completed plan to `plan/_archive/` and clears `plan/current/` — that is a separate commit, not the first one.

### What "Optional" means

Optional paths are generated by the setup script from sources in `ravintio-framework/`. You can safely `.gitignore` them and instruct contributors to run `setup.sh` after cloning. This keeps the repo lean. Alternatively, commit them so contributors get the files without running setup — both approaches work.

`ravintio-overrides/` is never optional — it contains your team's customisations and must be committed to be shared.

---

## Customising with ravintio-overrides

`ravintio-overrides/` is your team's customisation layer — committed to the repo, never overwritten by setup scripts.

### library-standards/

Override framework library preferences per language. Files here take precedence over `ravintio-framework/standards/library-standards/`:

```
ravintio-overrides/
└── library-standards/
    └── typescript/
        └── prefer-avoid.md    ← replaces the framework default for TypeScript
```

Agents check `ravintio-overrides/library-standards/` first. Structure matches the framework default.

### instructions/

Project-specific instructions appended to the boot file (e.g. `CLAUDE.md`) on every setup run. Idempotent — re-running setup replaces the previous block.

```
ravintio-overrides/
└── instructions/
    └── 01-project-context.md
    └── 02-naming-conventions.md
```

Files are sorted alphabetically and appended between HTML comment markers.

### capability-skills/

Permanent agent skills for this project. Each skill is a directory containing a `SKILL.md` with standard frontmatter. Setup copies them into the tool's skill directory alongside the built-in RAVINTIO skills:

```
ravintio-overrides/
└── capability-skills/
    └── my-project-skill/
        └── SKILL.md
```

---

*Source of truth: `ravintio-framework/`. See [getting-started.md](getting-started.md) for setup steps.*
