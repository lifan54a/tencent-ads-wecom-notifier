$ErrorActionPreference = 'Stop'
$taskName = 'TencentAdsLeadToWeCom'
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($null -eq $task) {
    Write-Host 'Status: not installed'
    exit 1
}
$info = Get-ScheduledTaskInfo -TaskName $taskName
Write-Host "Status: $($task.State)"
Write-Host "Last run: $($info.LastRunTime)"
Write-Host "Last result: $($info.LastTaskResult) (0 means success)"
Write-Host "Next run: $($info.NextRunTime)"

