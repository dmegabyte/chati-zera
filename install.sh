#!/usr/bin/env sh
# Установка chati-zera в конфиг OpenCode одной командой.
#
#   curl -fsSL https://raw.githubusercontent.com/dmegabyte/chati-zera/main/install.sh | sh
#   sh install.sh --mode zera
#
# По умолчанию ставит ЧАТИ и ZERA вместе в ~/.config/opencode.
set -eu

REPO="https://github.com/dmegabyte/chati-zera.git"
TARGET="${CONFIG_DIR:-$HOME/.config/opencode}"
MODE="both"
MODEL=""

usage() {
  cat <<'TXT'
Установка chati-zera.

  --dir PATH     куда ставить (по умолчанию ~/.config/opencode)
  --mode MODE    chati | zera | both (по умолчанию both)
  --model NAME   прописать модель, например openai/gpt-5
  -h, --help     эта справка
TXT
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) TARGET="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Неизвестный параметр: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  chati|zera|both) ;;
  *) echo "Режим должен быть chati, zera или both." >&2; exit 2 ;;
esac

if [ -f "$TARGET" ]; then
  echo "$TARGET — это файл, а не каталог." >&2
  exit 1
fi

if [ -d "$TARGET/.git" ]; then
  url="$(git -C "$TARGET" remote get-url origin 2>/dev/null || true)"
  case "$url" in
    *chati-zera*)
      echo "Обновляю $TARGET"
      git -C "$TARGET" pull --ff-only
      ;;
    *)
      echo "В $TARGET уже другой git-репозиторий ($url)." >&2
      echo "Укажите другой каталог: --dir PATH" >&2
      exit 1
      ;;
  esac
elif [ -e "$TARGET" ] && [ -n "$(ls -A "$TARGET" 2>/dev/null || true)" ]; then
  echo "Каталог $TARGET не пуст и это не chati-zera." >&2
  echo "Укажите другой каталог: --dir PATH" >&2
  exit 1
else
  echo "Клонирую в $TARGET"
  mkdir -p "$(dirname "$TARGET")"
  git clone "$REPO" "$TARGET"
fi

bash "$TARGET/scripts/bootstrap.sh"

if [ -n "$MODEL" ]; then
  sed -i "s|^\([[:space:]]*\)// \"model\": \"<provider>/<model>\",|\1\"model\": \"$MODEL\",|" "$TARGET/opencode.jsonc"
  if grep -q "\"model\": \"$MODEL\"" "$TARGET/opencode.jsonc"; then
    echo "Модель: $MODEL"
  else
    echo "Не смог прописать модель — добавьте вручную в $TARGET/opencode.jsonc" >&2
  fi
fi

if command -v python3 >/dev/null 2>&1; then
  python3 "$TARGET/scripts/profile.py" "$MODE"
else
  if [ "$MODE" = "both" ]; then
    echo "python3 не найден: режим both уже включён шаблоном."
  else
    echo "python3 не найден: переключите режим вручную после установки Python:" >&2
    echo "  python3 $TARGET/scripts/profile.py $MODE" >&2
  fi
fi

if ! command -v opencode >/dev/null 2>&1; then
  echo
  echo "OpenCode не найден. Установите: https://opencode.ai/docs"
fi

cat <<TXT

Готово. Дальше:
  opencode auth login
  opencode            # выберите модель в TUI через /model, если не задали
TXT
