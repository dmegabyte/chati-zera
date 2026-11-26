---
name: log-audit
description: Разбор локальных журналов сетевой активности на этом ПК и в WSL — какие запросы уходили (curl-log/http-audit), кто подключался снаружи (net-audit, журнал брандмауэра), и кто инициатор исходящего трафика (cron, systemd-таймер, планировщик Windows, процесс). Применяй на вопросы «что за запрос», «посмотри логи», «кто ко мне подключился», «куда уходит трафик», «почему в сети что-то шумит».
---

# Журналы запросов и подключений

## Инструменты

| Компонент | Путь | Назначение |
|---|---|---|
| `curl-log` | `~/.local/bin/curl-log` (WSL) | обёртка curl, пишет запись в журнал и выполняет запрос |
| `http-audit` | `~/.local/bin/http-audit` (WSL) | читалка журнала: фильтры и сводка |
| журнал | `~/.local/state/http-audit/outgoing.log` (ротация 5 МБ → `.1`) | факты исходящих curl |
| `net-audit` | `C:\Users\<user>\.local\bin\net-audit.ps1` | снимок установленных соединений с процессом и PID |
| отчёты net-audit | `C:\Users\<user>\.local\state\net-audit\summary-*.log` | результаты разовых снимков |
| непрерывный журнал | `C:\Users\<user>\.local\state\net-audit\connections-YYYYMMDD.log` | снимки каждые 5 минут по cron WSL (только внешние адреса), хранение 14 дней |
| журнал брандмауэра | `C:\Windows\System32\LogFiles\Firewall\pfirewall.log` | разрешённые и блокированные подключения (нужен админ) |

Из Windows журнал WSL доступен по `\\wsl.localhost\Ubuntu\home\ser\.local\state\http-audit\`.

## Непрерывный журнал подключений

В WSL cron каждые 5 минут запускает сэмплирование на 4 минуты с интервалом 10 секунд:

```
*/5 * * * * /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\<user>\.local\bin\net-audit.ps1" -Minutes 4 -IntervalSeconds 10 -ExternalOnly -Append
```

Записи дописываются в `connections-YYYYMMDD.log` в конце каждого окна; файлы старше 14 дней удаляются автоматически. Формат строки:
`HH:mm:ss OUT chrome 142.250.154.94:80 samples=3 first=19:05:06 last=19:05:36`.

Читать за сегодня: `Get-Content $env:USERPROFILE\.local\state\net-audit\connections-$(Get-Date -Format yyyyMMdd).log -Tail 40`. Искать конкретный адрес или процесс: `Select-String -Path ... -Pattern "chrome|91\.105\."`.

## Порядок разбора

1. Определи окно времени и направление (исходящее или входящее). Если пользователь говорит «только что» — бери последние 30–60 минут и сверяй с текущим временем команды.
2. Исходящие curl: `http-audit last 20`, затем `http-audit errors` и `http-audit stats`. Отдельно проверь `http-audit grep <домен|URL|процесс>`.
3. Если журнал пуст, а трафик есть — ищи инициатора: `crontab -l`, `journalctl -u cron --since ...`, `systemctl list-timers`, задачи планировщика Windows, запущенные процессы.
4. Входящие: `powershell -File $env:USERPROFILE\.local\bin\net-audit.ps1 -Minutes 10 -ExternalOnly`. Затем, при необходимости, копия журнала брандмауэра из-под администратора.
5. Сопоставь с процессами по PID и пути; для внешних адресов указывай направление `IN`/`OUT`.

## Команды

```bash
http-audit last 20          # последние записи целиком
http-audit url 20           # время, код, время ответа, URL
http-audit errors           # rc!=0 или HTTP>=400
http-audit grep n8n         # поиск по домену, URL, вызывающему
http-audit stats            # коды, распределение по часам, топ хостов
```

```powershell
wsl -e ~/.local/bin/http-audit last 20
powershell -File $env:USERPROFILE\.local\bin\net-audit.ps1 -Minutes 10 -ExternalOnly
```

```powershell
# журнал брандмауэра (в окне администратора)
Copy-Item C:\Windows\System32\LogFiles\Firewall\pfirewall.log $env:USERPROFILE\.local\state\net-audit\pfirewall-copy.log -Force
```

## Чтение записи

`ts | rc=<код curl> | <HTTP-код> <байты> <секунды> | err= | resp=<200 байт> | args= | caller=`

- `rc=0` — запрос выполнен; `28` — таймаут; `6` — DNS; `7` — соединение не установлено.
- `rc=0` + `404` — сервер ответил отказом (это не сетевая ошибка).
- `resp` — первые 200 байт ответа, по ним видно текст ошибки сервиса.
- `caller` — командная строка родителя: cron, shell, конкретный скрипт.

## Ограничения

- Журнал видит только вызовы через `curl-log`; браузер, мессенджеры, обновляторы и прочие приложения в него не попадают — для них только `net-audit` и журнал брандмауэра.
- Тела запросов не сохраняются; для payload нужен mitm-прокси, это отдельное согласование.
- `net-audit` — сэмплирование, а не полный захват: короткие соединения между сэмплами могут не попасть в отчёт.
- `pfirewall.log` читается только с правами администратора.

## Отчёт

Указывай: окно времени, источник данных, инициатора (процесс/PID/cron-строка), направление, адрес, код ответа, и отдельно — что осталось неподтверждённым. Ссылайся на конкретные строки журнала или файлы.

## Безопасность

- Работа только на чтение. Не менять cron, брандмауэр, задачи и не удалять журналы без явного подтверждения пользователя.
- В URL могут быть токены и ключи: при цитировании маскируй секретную часть.
- Не включать и не выключать сетевые функции «для чистоты» в рамках диагностики.
