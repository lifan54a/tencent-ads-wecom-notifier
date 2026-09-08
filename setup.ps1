$ErrorActionPreference = 'Stop'

function Read-EncryptedValue([string]$Prompt, [byte[]]$Key) {
    $secure = Read-Host $Prompt -AsSecureString
    return ConvertFrom-SecureString $secure -Key $Key
}

$key = [byte[]]::new(32)
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($key)
$keyPath = Join-Path $PSScriptRoot 'config.key'
[Convert]::ToBase64String($key) | Set-Content -LiteralPath $keyPath -Encoding ASCII
$config = [ordered]@{
    token = Read-EncryptedValue 'Tencent Ads Token' $key
    secret = Read-EncryptedValue 'Tencent Ads Secret' $key
    wecomWebhook = Read-EncryptedValue 'WeCom webhook URL' $key
    apiUrl = 'https://leads.qq.com/api/mv1/leads/list'
    pollLookbackSeconds = 180
    maskPhone = $false
}

$path = Join-Path $PSScriptRoot 'config.secure.json'
$config | ConvertTo-Json | Set-Content -LiteralPath $path -Encoding UTF8
Write-Host "Encrypted configuration saved to: $path"
Write-Host 'Run: powershell -ExecutionPolicy Bypass -File .\poll-leads.ps1'
