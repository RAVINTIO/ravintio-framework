---
title: "Domain Glossary - credential-scan-word-boundary"
summary: "Terms used in 0000044."
---
# Domain Glossary - credential-scan-word-boundary

| Term | Definition |
|------|-----------|
| Content rule | One named regular expression in `CONTENT_RULES`. The scan reports `{path}:{line} {rule}` for each line that a rule matches. |
| Word character | An ASCII letter, a digit, or `_`. The JavaScript `\b` assertion sits between a word character and any other character, or at a line edge. Without the `u` flag, a non-ASCII letter such as `é` isn't a word character. |
| Word boundary | The point where `\b` holds. The new `api-secret-key` rule needs one directly before `sk-`. |
| Hold-back | A file that the pre-commit credential scan keeps out of an autonomous commit. The build log records it as `Credential scan (P{N}): held back {path}`. |
| Hash line | One `files:` entry in `release.yml`: a pack path and its SHA-256 hash. |
