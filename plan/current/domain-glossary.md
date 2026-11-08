---
title: "Domain Glossary - fix-windows-shards-pr-77"
summary: "Terms used in the 0000042 Windows suite fix."
---
# Domain Glossary - fix-windows-shards-pr-77

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Windows shard | One of the seven `windows-latest` test jobs. Each runs a slice of `run-tests.sh` under Git Bash. | shard | `ravintio-framework` |
| `IS_WIN` | A suite variable. It reads `yes` when `uname -s` starts with `MINGW`, `MSYS`, or `CYGWIN`. | none | `ravintio-framework` |
| Windows skip | A case that a suite doesn't run on Windows. It prints one `SKIP (windows): {reason}` line and counts as neither a pass nor a fail. | skip line | `ravintio-framework` |
| Blob id | The SHA-1 that git gives a file's content after its clean filters, such as line-ending conversion. | object id | `ravintio-framework` |
| Release copy | The root `ravintio-framework/` folder that the release script rebuilds from `src/ravintio-framework/` at P7. | root copy | `ravintio-framework` |
