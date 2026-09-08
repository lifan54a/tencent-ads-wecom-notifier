$ErrorActionPreference = 'Stop'
& powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'poll-leads.ps1') -TestOnly
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

