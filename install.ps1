$ErrorActionPreference = 'Stop'

$setupScript = Join-Path $PSScriptRoot 'setup.ps1'
$pollScript = Join-Path $PSScriptRoot 'poll-leads.ps1'
$taskScript = Join-Path $PSScriptRoot 'install-task.ps1'

Write-Host 'Tencent Ads Lead -> WeCom Notifier'
Write-Host 'Enter the three requested credentials. Input is hidden.'
Write-Host ''

& powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $setupScript
if ($LASTEXITCODE -ne 0) { throw 'Configuration failed.' }

Write-Host ''
Write-Host 'Testing Tencent Ads API and WeCom webhook...'
& powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $pollScript -TestOnly
if ($LASTEXITCODE -ne 0) { throw 'Connection test failed. Scheduled task was not installed.' }

Write-Host ''
Write-Host 'Installing the hidden one-minute scheduled task...'
& powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $taskScript
if ($LASTEXITCODE -ne 0) { throw 'Scheduled task installation failed.' }

Start-ScheduledTask -TaskName 'TencentAdsLeadToWeCom'
Start-Sleep -Seconds 3
$info = Get-ScheduledTaskInfo -TaskName 'TencentAdsLeadToWeCom'
if ($info.LastTaskResult -ne 0 -and $info.LastTaskResult -ne 267009) {
    throw "Initial scheduled run failed with result: $($info.LastTaskResult)"
}

Write-Host ''
Write-Host 'Installation completed successfully.' -ForegroundColor Green
Write-Host 'The notifier now runs silently every minute.'

