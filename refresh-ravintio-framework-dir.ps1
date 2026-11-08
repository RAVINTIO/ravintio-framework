$repoDir = $PSScriptRoot

# The root ravintio-framework\ folder is the release copy. P7 rebuilds it from
# src\ravintio-framework\, so .claude\ installs from the release.

# Remove Claude
Remove-Item -Path "$repoDir\.claude\" -Recurse -EA SilentlyContinue
Remove-Item -Path "$repoDir\AGENTS.md" -EA SilentlyContinue
Remove-Item -Path "$repoDir\CLAUDE.md" -EA SilentlyContinue

# Re-add Claude
Set-Location $repoDir
.\ravintio-framework\setup.ps1 claude-code --include-full-skill-library
