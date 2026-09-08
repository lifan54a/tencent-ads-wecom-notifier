$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'poll-leads.ps1'
$launcher = Join-Path $PSScriptRoot 'run-hidden.vbs'
$taskName = 'TencentAdsLeadToWeCom'
$action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument "//B //Nologo `"$launcher`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description 'Poll Tencent Ads leads and notify WeCom' -Force | Out-Null
Write-Host "Scheduled task installed: $taskName (runs every minute)"
