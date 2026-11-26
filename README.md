# opencode-standard

Переиспользуемая агентская конфигурация для [OpenCode](https://opencode.ai): правила,
роли, процедуры и шаблоны. Без личных настроек, ключей и проектных данных.

## Что внутри

| Путь | Назначение |
|---|---|
| `AGENTS.md` | конституция: 9 разделов — фокус, стиль, evidence, инструменты, границы, проверка, делегирование, git, ZERA |
| `core-rules.md` | кардинальное правило: только проверяемые источники и ссылка на источник |
| `chati-style.md` | стиль объяснений: короткий вывод, простой язык, без канцелярита |
| `agents/` | 9 ролей: `chati`, `fast-chati`, `executor`, `coder`, `evidence-scout`, `code-reviewer`, `deep-research`, `promptmaster`, `ui-inspector` |
| `skills/` | 7 процедур: ZERA-уборка, стандартизация проекта, housekeeping, восстановление после инцидента, windows-health, log-audit, disk-cleanup |
| `templates/` | шаблоны `opencode.jsonc` для Linux и Windows + локальный оверлей |
| `scripts/bootstrap.*` | заполнение локального конфига из шаблона |

## Установка

```sh
git clone https://github.com/dmegabyte/opencode-standard ~/.config/opencode
cd ~/.config/opencode
./scripts/bootstrap.sh
```

Windows:

```powershell
git clone https://github.com/dmegabyte/opencode-standard $env:USERPROFILE\.config\opencode
cd $env:USERPROFILE\.config\opencode
.\scripts\bootstrap.ps1
```

Модель по умолчанию — `opencode-go/deepseek-v4.1-flash`. Если у вас нет доступа к этому
провайдеру, замените `model` в `opencode.jsonc` на свою.

Дальше: `opencode auth login`, затем `opencode api get /api/agent` — должны появиться
9 ролей. Скрипт не перезаписывает существующие `opencode.jsonc` и `AGENTS.local.md`.

## Как это устроено

1. **Слои правил.** Конституция (`AGENTS.md`) + кардинальное правило + стиль подключаются
   через `instructions` в локальном конфиге. Машинные отличия — в `AGENTS.local.md`.
2. **Роли.** Каждая роль — markdown с frontmatter: описание, модель, режим, права.
3. **Процедуры.** Скиллы вызываются по задаче, а не висят в контексте постоянно.
4. **Границы.** Секреты, плагины, базы и логи не входят в репозиторий.

## Чего здесь нет

- Личных MCP-серверов, токенов и OAuth-сессий.
- Проектных ролей и скиллов (CRM, недвижимость, внутренние пайплайны).
- Плагинов: они подключаются локально.

## Принципы

- Факт без источника не считается фактом.
- `AGENTS.md` — конституция, а не отчёт: без счётчиков файлов и дат.
- Делегирование только по делу: один помощник, максимум два на независимых задачах.
- Проверка результата до объявления готовности.

## Лицензия

MIT, см. `LICENSE`.
