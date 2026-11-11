# Verify-by-Execution Report

**Feature:** 0000044-credential-scan-word-boundary
**Toggle:** on
**Software exercised:** `node src/ravintio-framework/scripts/credential-scan.mjs`, run from the repository root in file mode, staged mode, and safe-paths mode. Staged and safe-paths runs used a throwaway git repository in the session scratch directory, which the checker removed afterwards.

**Result:** criteria 1, 2, 4, 5, and 6 verified. Criterion 3 is partly verified now and the rest is deferred to P7. No criterion failed.

## Fixtures

The checker built every fixture at run time in the session scratch directory under `verify/fx/`. Each key is `sk-` followed by 24 characters from `[A-Za-z0-9_]`. No fixture text sits in any repository file.

| Fixture | Line shape |
|---------|-----------|
| `hashline.yml` | Two spaces, a quoted path under `external-skills/` in the vendored risk requirements analysis skill folder, a colon, a space, and a quoted 64-character hex hash |
| `after-letter.txt` | `x` then the key |
| `after-digit.txt` | `7` then the key |
| `after-underscore.txt` | `_` then the key |
| `col1.txt` | The key at column 1 |
| `after-equals.txt` | `KEY=` then the key |
| `after-dquote.txt` | `k "` then the key and a closing quote |
| `after-space.txt` | `x ` then the key |
| `after-colon.txt` | `key:` then the key |

Control run: the old pattern `/sk-[A-Za-z0-9_-]{20,}/` matches `hashline.yml` (`true`). The new pattern `/\bsk-[A-Za-z0-9_-]{20,}/` does not (`false`). The fixture reproduces the false hold-back.

## Criteria

| Requirement | Criterion | Method | Outcome | Observation evidence |
|-------------|-----------|--------|---------|---------------------|
| REQ-001 | 1. `--file` exits 0 on the `release.yml` hash line and on `sk-` after a letter, a digit, and `_` | CLI | verified | `node src/ravintio-framework/scripts/credential-scan.mjs --file {fx}/hashline.yml`, then the same for `after-letter.txt`, `after-digit.txt`, and `after-underscore.txt`. Each exits 0 and prints only `scan mode: regex only (gitleaks not found)`. |
| REQ-001 | 2. `--file` exits 1 and reports `api-secret-key` at line start and after `=`, a double quote, and a space | CLI | verified | `--file {fx}/col1.txt`, `after-equals.txt`, `after-dquote.txt`, and `after-space.txt`. Each exits 1 and prints `{path}:1 api-secret-key`. No output holds the key text. |
| REQ-001 | 3. At P7 the scan passes the rebuilt `release.yml`, and the P7 commit includes it | CLI, git | deferred | Run now: `node src/ravintio-framework/scripts/credential-scan.mjs --file ravintio-framework/release.yml` exits 0 with no hit. `node src/ravintio-framework/scripts/credential-scan.mjs --safe-paths {scratch}/safe-real.out -- ravintio-framework/release.yml` exits 0, and the out-file lists `ravintio-framework/release.yml`. This file is the stale, untracked build from 0.39.2 sources. Deferred to P7: the scan of the rebuilt `release.yml`, and `git ls-files` showing it after the P7 commit. |
| REQ-001 | 4. Negative-case output holds no `api-secret-key` line, and the hash-line fixture copies the real shape | CLI, file inspection | verified | The four criterion 1 runs print no `api-secret-key` line. `hashline.yml` has the shape of line 634 of `ravintio-framework/release.yml`: two spaces, quoted path, colon, space, and quoted 64-character hash. |
| REQ-001 | 5. `--file` exits 1 and reports `api-secret-key` after a colon | CLI | verified | `--file {fx}/after-colon.txt` exits 1 and prints `{path}:1 api-secret-key`. |
| REQ-001 | 6. `src/ravintio-framework/component.yml` reads version `0.39.3` | File inspection | verified | `grep -n '^version' src/ravintio-framework/component.yml` prints `4:version: "0.39.3"`. |

## Mode parity

The rule behaves the same in every mode. In the throwaway repository, the checker staged all nine fixtures and a copy of `ravintio-framework/release.yml`.

| Mode | Command | Exit | Held back with `api-secret-key` | Clean |
|------|---------|------|-------------------------------|-------|
| Staged | `node {script}` | 1 | `col1.txt`, `after-equals.txt`, `after-dquote.txt`, `after-space.txt`, `after-colon.txt` | `hashline.yml`, `release.yml`, `after-letter.txt`, `after-digit.txt`, `after-underscore.txt` |
| Safe-paths | `node {script} --safe-paths {scratch}/safe.out -- {all ten paths}` | 1 | The same five paths | The out-file lists the same five clean paths |
| File | `node {script} --file {path}` per fixture | 1 or 0 | The same five fixtures exit 1 | The same five fixtures exit 0 |

No background process remains.
