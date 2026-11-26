#!/usr/bin/env python3
"""Проверки публичного репозитория: ссылки, frontmatter, JSON-шаблоны.

Запуск: python3 scripts/check.py
"""
import json
import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
errors = []


def rel(path: Path) -> str:
    return str(path.relative_to(root))


# 1. Внутренние ссылки в markdown
for path in root.rglob("*.md"):
    if ".git" in path.parts:
        continue
    text = path.read_text(encoding="utf-8")
    for match in re.finditer(r"\[[^\]]*\]\(([^)]+)\)", text):
        target = match.group(1).split("#")[0]
        if not target or target.startswith(("http://", "https://", "mailto:")):
            continue
        if not (path.parent / target).exists():
            errors.append(f"{rel(path)}: ссылка не найдена: {target}")

# 2. Frontmatter ролей и скиллов
for folder in ("agents", "skills"):
    base = root / folder
    if not base.exists():
        continue
    for path in base.rglob("*.md"):
        text = path.read_text(encoding="utf-8")
        if not text.startswith("---\n"):
            errors.append(f"{rel(path)}: нет frontmatter")
            continue
        block = text.split("---", 2)[1]
        if "name:" not in block and "description:" not in block:
            errors.append(f"{rel(path)}: нет name или description")

# 3. JSONC-шаблоны
for path in root.rglob("*.jsonc"):
    if ".git" in path.parts:
        continue
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"^\s*//.*$", "", text, flags=re.M)
    text = re.sub(r",(\s*[}\]])", r"\1", text)
    try:
        json.loads(text)
    except Exception as exc:  # noqa: BLE001
        errors.append(f"{rel(path)}: невалидный JSON: {exc}")

if errors:
    print("\n".join(errors))
    sys.exit(1)

print("ok: ссылки, frontmatter, json")
