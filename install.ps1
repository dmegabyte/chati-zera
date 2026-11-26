# Установка chati-zera в конфиг OpenCode одной командой.
#
#   irm https://raw.githubusercontent.com/dmegabyte/chati-zera/main/install.ps1 | iex
#   .\install.ps1 -Mode zera
#
# По умолчанию ставит ЧАТИ и ZERA вместе в %USERPROFILE%\.config\opencode.
param(
  [string]$Dir = "$env:USERPROFILE\.config\opencode",
  [ValidateSet("chati", "zera", "both")][string]$Mode = "both",
  [string]$Model
)

$ErrorActionPreference = "Stop"
$Repo = "https://github.com/dmegabyte/chati-zera.git"

if (Test-Path $Dir -PathType Leaf) {
  throw "$Dir — это файл, а не каталог."
}

if (Test-Path "$Dir\.git") {
  $url = git -C $Dir remote get-url origin
  if ($url -notmatch "chati-zera") {
    throw "В $Dir уже другой git-репозиторий ($url). Укажите другой каталог: -Dir PATH"
  }
  Write-Host "Уже установлено: $Dir"
  Write-Host "Обновление: cd $Dir; python scripts/profile.py both; git pull"
} elseif ((Test-Path $Dir) -and ((Get-ChildItem $Dir -Force | Measure-Object).Count -gt 0)) {
  throw "Каталог $Dir не пуст и это не chati-zera. Укажите другой: -Dir PATH"
} else {
  Write-Host "Клонирую в $Dir"
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Dir) | Out-Null
  git clone $Repo $Dir
}

& "$Dir\scripts\bootstrap.ps1"

if ($Model) {
  $path = "$Dir\opencode.jsonc"
  $text = Get-Content $path -Raw
  $new = $text -replace '(?m)^\s*// "model": "<provider>/<model>",', "  `"model`": `"$Model`","
  [IO.File]::WriteAllText($path, $new, [Text.UTF8Encoding]::new($false))
  if ($new -match [regex]::Escape("`"model`": `"$Model`"")) {
    Write-Host "Модель: $Model"
  } else {
    Write-Warning "Не смог прописать модель — добавьте вручную в $path"
  }
}

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python3 -ErrorAction SilentlyContinue }
if ($py) {
  & $py.Source "$Dir\scripts\profile.py" $Mode
} else {
  if ($Mode -eq "both") {
    Write-Host "python не найден: режим both уже включён шаблоном."
  } else {
    Write-Warning "python не найден: переключите режим вручную после установки Python."
  }
}

if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
  Write-Host ""
  Write-Host "OpenCode не найден. Установите: https://opencode.ai/docs"
}

Write-Host ""
Write-Host "Готово. Дальше:"
Write-Host "  opencode auth login"
Write-Host "  opencode            # выберите модель в TUI через /model, если не задали"
