# Заполняет локальный конфиг из шаблона. Запускать из клона репозитория.
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$cfg = $root -replace '\\', '/'

if (-not (Test-Path "$root\opencode.jsonc")) {
  $text = (Get-Content "$root\templates\opencode.windows.jsonc" -Raw).
    Replace('{{CONFIG_DIR}}', $cfg).
    Replace('{{HOME_WIN}}', $env:USERPROFILE)
  [IO.File]::WriteAllText("$root\opencode.jsonc", $text, [Text.UTF8Encoding]::new($false))
  Write-Host "created: opencode.jsonc"
} else {
  Write-Host "skip: opencode.jsonc already exists"
}

if (-not (Test-Path "$root\AGENTS.local.md")) {
  Copy-Item "$root\templates\AGENTS.local.windows.md" "$root\AGENTS.local.md"
  Write-Host "created: AGENTS.local.md"
} else {
  Write-Host "skip: AGENTS.local.md already exists"
}

Write-Host ""
Write-Host "Next:"
Write-Host "  opencode auth login"
Write-Host "  opencode api get /api/agent   # expect 9 custom agents"
Write-Host "  opencode run `"Reply with OK`""
