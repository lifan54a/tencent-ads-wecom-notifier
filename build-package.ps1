$ErrorActionPreference = 'Stop'
$packageName = 'tencent-ads-wecom-skill'
$stage = Join-Path $PSScriptRoot $packageName
$zip = Join-Path $PSScriptRoot ($packageName + '.zip')

if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null

$files = @(
    'SKILL.md',
    'install.cmd', 'install.ps1', 'setup.ps1', 'poll-leads.ps1',
    'install-task.ps1', 'run-hidden.vbs', 'test.cmd', 'test.ps1',
    'status.cmd', 'status.ps1', 'uninstall.cmd', 'uninstall.ps1',
    'README.md', '.gitignore'
)
foreach ($file in $files) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination $stage
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'agents') -Destination $stage -Recurse
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'references') -Destination $stage -Recurse
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -LiteralPath $stage -DestinationPath $zip -CompressionLevel Optimal
Write-Host "Package created: $zip"
