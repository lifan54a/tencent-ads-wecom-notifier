param([switch]$TestOnly)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Unprotect([string]$CipherText, [byte[]]$Key) {
    $secure = ConvertTo-SecureString $CipherText -Key $Key
    return [System.Net.NetworkCredential]::new('', $secure).Password
}

function Mask-Phone([string]$Phone) {
    if ([string]::IsNullOrWhiteSpace($Phone) -or $Phone.Length -lt 7) { return $Phone }
    return $Phone.Substring(0, 3) + '****' + $Phone.Substring($Phone.Length - 4)
}

function Escape-Markdown([object]$Value) {
    if ($null -eq $Value) { return '-' }
    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) { return '-' }
    return $text.Replace('<', '[').Replace('>', ']')
}

$configPath = Join-Path $PSScriptRoot 'config.secure.json'
$keyPath = Join-Path $PSScriptRoot 'config.key'
$statePath = Join-Path $PSScriptRoot 'state.json'
if (-not (Test-Path -LiteralPath $configPath) -or -not (Test-Path -LiteralPath $keyPath)) {
    throw 'Missing encrypted configuration. Run setup.ps1 first.'
}

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$key = [Convert]::FromBase64String((Get-Content -LiteralPath $keyPath -Raw).Trim())
$token = Unprotect $config.token $key
$secret = Unprotect $config.secret $key
$webhook = Unprotect $config.wecomWebhook $key

$now = [DateTimeOffset]::Now
$lastPoll = $now.AddSeconds(-[int]$config.pollLookbackSeconds)
$seen = [System.Collections.Generic.HashSet[string]]::new()
if (Test-Path -LiteralPath $statePath) {
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($state.lastPoll) { $lastPoll = [DateTimeOffset]::Parse($state.lastPoll) }
    foreach ($id in @($state.seenIds)) { [void]$seen.Add([string]$id) }
}

# Overlap protects against boundary/race conditions. leads_id de-duplicates repeats.
$start = $lastPoll.AddSeconds(-30).ToUnixTimeSeconds()
$end = $now.ToUnixTimeSeconds()
$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$nonce = [Guid]::NewGuid().ToString('N').Substring(0, 32)
$seedText = "$token.$timestamp.$secret"
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $hashBytes = $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($seedText))
} finally {
    $sha256.Dispose()
}
$hash = -join ($hashBytes | ForEach-Object { $_.ToString('x2') })
$signatureRaw = "$token,$timestamp,$nonce,$hash"
$signature = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($signatureRaw))

$query = 'start_time={0}&end_time={1}&time_type=1&page_size=200&page=1' -f $start, $end
$uri = "$($config.apiUrl)?$query"
$headers = @{
    'X-Signature' = $signature
    'X-Signature-Algorithm' = 'SHA256'
    'Accept' = 'application/json'
}
$response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -TimeoutSec 30
if ([int]$response.code -ne 0) {
    throw "Tencent Ads API error: code=$($response.code), message=$($response.message)"
}

$newLeads = @($response.data.list) | Where-Object {
    $_.leads_id -and -not $seen.Contains([string]$_.leads_id)
} | Sort-Object leads_create_time

if ($TestOnly) {
    $body = @{
        msgtype = 'markdown'
        markdown = @{ content = "### Tencent Ads integration test`n> API connection successful`n> Poll time: $($now.ToString('yyyy-MM-dd HH:mm:ss'))" }
    } | ConvertTo-Json -Depth 4
    $wecomResult = Invoke-RestMethod -Method Post -Uri $webhook -ContentType 'application/json; charset=utf-8' -Body $body -TimeoutSec 20
    if ([int]$wecomResult.errcode -ne 0) {
        throw "WeCom send error: errcode=$($wecomResult.errcode), errmsg=$($wecomResult.errmsg)"
    }
    Write-Host "Connection test passed. Tencent Ads returned $(@($response.data.list).Count) lead(s) in the test window; no lead details were sent."
    exit 0
}

foreach ($lead in $newLeads) {
    $phone = [string]$lead.leads_tel
    if ([bool]$config.maskPhone) { $phone = Mask-Phone $phone }
    $content = @(
        '### 🔔 腾讯广告新线索'
        "> 姓名：$(Escape-Markdown $lead.leads_name)"
        "> 电话：$(Escape-Markdown $phone)"
        "> 所在地区：$(Escape-Markdown $lead.leads_area)"
        "> 号码归属地：$(Escape-Markdown $lead.tel_location)"
        "> 推广计划：$(Escape-Markdown $lead.campaign_name)"
        "> 广告名称：$(Escape-Markdown $lead.ad_name)"
        "> 提交时间：$(Escape-Markdown $lead.leads_action_time)"
        "> 线索 ID：$(Escape-Markdown $lead.leads_id)"
    ) -join "`n"
    $body = @{ msgtype = 'markdown'; markdown = @{ content = $content } } | ConvertTo-Json -Depth 4
    $wecomResult = Invoke-RestMethod -Method Post -Uri $webhook -ContentType 'application/json; charset=utf-8' -Body $body -TimeoutSec 20
    if ([int]$wecomResult.errcode -ne 0) {
        throw "WeCom send error: errcode=$($wecomResult.errcode), errmsg=$($wecomResult.errmsg)"
    }
    [void]$seen.Add([string]$lead.leads_id)
}

# Bound local state while retaining enough IDs for overlapping polls.
$seenIds = @($seen)
if ($seenIds.Count -gt 5000) { $seenIds = $seenIds[($seenIds.Count - 5000)..($seenIds.Count - 1)] }
@{ lastPoll = $now.ToString('o'); seenIds = $seenIds } |
    ConvertTo-Json -Depth 3 |
    Set-Content -LiteralPath $statePath -Encoding UTF8

Write-Host "Completed: sent $($newLeads.Count) new lead(s)."
