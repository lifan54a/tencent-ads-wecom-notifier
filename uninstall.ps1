$ErrorActionPreference = 'Stop'
$taskName = 'TencentAdsLeadToWeCom'
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host 'Scheduled task removed.'
} else {
    Write-Host 'Scheduled task is not installed.'
}
Write-Host 'Encrypted credentials remain in this folder. Delete config.secure.json and config.key manually if no longer needed.'

