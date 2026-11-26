#!/usr/bin/env bash
# Заполняет локальный конфиг из шаблона. Запускать из клона репозитория.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -f "$root/opencode.jsonc" ]; then
  sed -e "s|{{CONFIG_DIR}}|$root|g" -e "s|{{HOME}}|$HOME|g" \
    "$root/templates/opencode.wsl.jsonc" > "$root/opencode.jsonc"
  echo "created: opencode.jsonc"
else
  echo "skip: opencode.jsonc already exists"
fi

if [ ! -f "$root/AGENTS.local.md" ]; then
  cp "$root/templates/AGENTS.local.wsl.md" "$root/AGENTS.local.md"
  echo "created: AGENTS.local.md"
else
  echo "skip: AGENTS.local.md already exists"
fi

cat <<TXT

Next:
  opencode auth login
  opencode api get /api/agent     # expect 21 agents
  opencode run "Reply with OK"
TXT
