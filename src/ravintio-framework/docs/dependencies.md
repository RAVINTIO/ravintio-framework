# Dependencies - ravintio-framework

Last updated: 0000041-pack-source-under-src

## Consumes

| Dependency | Type | Use |
|---|---|---|
| Node.js built-in modules | Runtime | `build-release.mjs`, `release-check.mjs`, and `project-kind.mjs` use no package (0000041 ADR-001). |
| `git` | Tool | `build-release.mjs` runs `git ls-files` and `git rev-parse`. `release-check.mjs` runs `git ls-files`. Both force `core.fsmonitor=false`. |
| `hooks/enforcement/path-rules.mjs` | Internal | `build-release.mjs` uses `resolveRoot`. |
| `product.yml` | Repo file | `project-kind.mjs` reads the component list. The file belongs to the project. |
| `plan/framework-release.yml` | Repo file | `release-check.mjs` reads the last trusted release. Step 1a writes it. |
| `docs/about.md` | Repo file | `release-check.mjs` reads the version on a first upgrade. |

## Depended on by

| Consumer | What it uses |
|---|---|
| `setup-hook-integration` | Its code lives under `src/ravintio-framework/` (`setup.sh`, `setup.ps1`, `setup/`, `hooks/`, `scripts/skill-sync.sh`). |
| Orchestrator step 1a | `release-check.mjs` and `release.yml`. |
| Migrator | `project-kind.mjs` and the `**Applies to:**` header. |
| `ravintio-ship-agent` | `build-release.mjs` at P7 Step 5c. |
| CI `release-copy-integrity` job | `release-check.mjs --files-only`. |
| Every suite under `tests/` | `tests/helpers/pack-root.sh` to find the pack and the repo root. |
| Consumer repos | The root `ravintio-framework/` copy and its migrations. |

## Direction rules

- `src/ravintio-framework/` never imports from the root copy.
- The root copy has no dependency on `src/`. Consumers have no `src/ravintio-framework/`.
- `setup-hook-integration` depends on this component. This component does not depend on it.
