#!/usr/bin/env python3
"""Переключение режимов chati-zera: chati | zera | both.

- Меняет состав `instructions` в opencode.jsonc.
- Включает и выключает каталоги `agents/` и `skills/`, переименовывая их в `*.off`.
- В режиме `zera` убирает `AGENTS.md` (правила персоны), переименовывая его в `AGENTS.chati.md`.
- Записывает выбранный режим в `.profile`.

Запуск: python3 scripts/profile.py chati|zera|both
"""
import re
import sys
from pathlib import Path

MODES = {
    "chati": {"agents": True, "skills": False, "zera": False},
    "zera": {"agents": False, "skills": True, "zera": True},
    "both": {"agents": True, "skills": True, "zera": True},
}

root = Path(__file__).resolve().parent.parent
config = root / "opencode.jsonc"


def toggle_dir(name: str, enabled: bool) -> None:
    live = root / name
    off = root / f"{name}.off"
    if enabled:
        if off.is_dir() and not live.is_dir():
            off.rename(live)
        elif off.is_dir() and live.is_dir():
            print(f"warning: {name} и {name}.off существуют одновременно")
    else:
        if live.is_dir() and not off.is_dir():
            live.rename(off)


def toggle_file(live_name: str, off_name: str, enabled: bool) -> None:
    live = root / live_name
    off = root / off_name
    if enabled:
        if off.exists() and not live.exists():
            off.rename(live)
        elif off.exists() and live.exists():
            print(f"warning: {live_name} и {off_name} существуют одновременно")
    else:
        if live.exists() and not off.exists():
            live.rename(off)


def instructions(mode: dict) -> str:
    files = []
    if mode["zera"]:
        files.extend(["core-rules.md", "ZERA.md"])
    if mode["agents"]:
        files.append("chati-style.md")
    files.append("AGENTS.local.md")
    body = ",\n".join('    "{{DIR}}/' + f + '"' for f in files)
    return f'"instructions": [\n{body}\n  ],'


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in MODES:
        print("usage: python3 scripts/profile.py chati|zera|both")
        return 2
    name = sys.argv[1]
    mode = MODES[name]

    toggle_dir("agents", mode["agents"])
    toggle_dir("skills", mode["skills"])
    toggle_file("AGENTS.md", "AGENTS.chati.md", mode["agents"])

    if config.exists():
        text = config.read_text(encoding="utf-8")
        text = text.replace("{{CONFIG_DIR}}", root.as_posix()).replace("{{DIR}}", root.as_posix())
        block = instructions(mode).replace("{{DIR}}", root.as_posix())
        text, count = re.subn(r'"instructions":\s*\[.*?\],', block, text, count=1, flags=re.S)
        if count == 0:
            print("warning: блок instructions не найден в opencode.jsonc")
        config.write_text(text, encoding="utf-8")
    else:
        print("warning: opencode.jsonc не найден — режим применён только к каталогам")

    (root / ".profile").write_text(name + "\n", encoding="utf-8")
    print(
        f"режим: {name} | агенты: {'вкл' if mode['agents'] else 'выкл'} | "
        f"скиллы: {'вкл' if mode['skills'] else 'выкл'} | ZERA: {'вкл' if mode['zera'] else 'выкл'}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
