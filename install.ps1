# avenoxstatusline-windows installer
#   irm https://raw.githubusercontent.com/riqas/avenoxstatusline-windows/main/install.ps1 | iex
#
# 1. installs jq via winget if it can't be found
# 2. downloads statusline.sh to ~/.claude/statusline.sh
# 3. adds "statusLine" to ~/.claude/settings.json (backup written next to it)

$ErrorActionPreference = 'Stop'
$repo    = 'https://raw.githubusercontent.com/riqas/avenoxstatusline-windows/main'
$claude  = Join-Path $HOME '.claude'
$script  = Join-Path $claude 'statusline.sh'
$settings = Join-Path $claude 'settings.json'

New-Item -ItemType Directory -Force $claude | Out-Null

# --- 1. jq ---
$wingetJq = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\jqlang.jq_*\jq.exe" -ErrorAction SilentlyContinue
if (-not (Get-Command jq -ErrorAction SilentlyContinue) -and -not $wingetJq) {
    Write-Host 'jq not found - installing with winget...'
    winget install --id jqlang.jq -e --silent --accept-source-agreements --accept-package-agreements
} else {
    Write-Host 'jq: ok'
}

# --- 2. script (downloaded as bytes so LF line endings survive) ---
Invoke-WebRequest "$repo/statusline.sh" -OutFile $script -UseBasicParsing
Write-Host "statusline: $script"

# --- 3. settings.json ---
if (Test-Path $settings) {
    $backup = "$settings.bak-statusline"
    Copy-Item $settings $backup -Force
    Write-Host "backup: $backup"
    $raw = [IO.File]::ReadAllText($settings)
    $cfg = if ($raw.Trim()) { $raw | ConvertFrom-Json } else { [pscustomobject]@{} }
} else {
    $cfg = [pscustomobject]@{}
}

$line = [pscustomobject]@{ type = 'command'; command = 'bash ~/.claude/statusline.sh'; refreshInterval = 3 }
$cfg | Add-Member -NotePropertyName statusLine -NotePropertyValue $line -Force

# UTF-8 without BOM: Windows PowerShell 5.1's -Encoding UTF8 would add one
[IO.File]::WriteAllText($settings, ($cfg | ConvertTo-Json -Depth 100), (New-Object Text.UTF8Encoding $false))
Write-Host 'settings.json: statusLine set'
Write-Host ''
Write-Host 'Done. Restart Claude Code to see the bear.'
