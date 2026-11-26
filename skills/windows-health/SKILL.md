---
name: windows-health
description: Полная диагностика Windows без переустановки — стабильность и BSOD, проблемные драйверы, журналы событий, файл подкачки и commit, диски и SMART, службы, загрузка, обновления, очистка. Применяй на вопросы «система нестабильна», «вылетает синий экран», «ошибка драйвера», «почему тормозит», «посмотри логи Windows», «что за ошибка в журнале», «почистить систему», «проверить диск и память», «настроить Windows».
---

# Диагностика и обслуживание Windows

Навык про здоровье самой ОС: сбои, драйверы, журналы, память, диски, очистка. Про сеть — `log-audit`, про место на диске и проекты — `disk-cleanup`, про репозитории — `zera-cleanup`. Этот навык их не заменяет.

## Границы

- По умолчанию **только чтение**: сбор фактов и отчёт. Никаких твиков реестра, отключения служб, «оптимизации», установки драйверов и удаления файлов без отдельного подтверждения точного действия.
- Диагностика ≠ исправление. Сначала отчёт с доказательствами (event id, путь, код ошибки), потом план, потом согласование.
- Перед словом «баг» применяй `Actual / Contract / Desired`: что делает система, что заявлено, что должно быть. Если Desired неизвестен — спроси.
- Не запускай сторонние твикеры (WinUtil, Optimizer, Sophia, Win11Debloat) от имени агента. Только инструкция для ручного запуска.

## Инструменты

| Компонент | Путь | Назначение |
|---|---|---|
| `audit.ps1` | `C:\Users\<user>\.local\bin\win-health\audit.ps1` | снимок здоровья: ОС, память, подкачка, журналы, сбои, устройства, диски, службы, загрузка, обновления, VSS, pending reboot |
| `drivers.ps1` | `C:\Users\<user>\.local\bin\win-health\drivers.ps1` | драйверы: старые, неподписанные, свежие, Driver Store и дубли INF |
| `cleanup-audit.ps1` | `C:\Users\<user>\.local\bin\win-health\cleanup-audit.ps1` | замер кандидатов на очистку с классами safe/review/keep |
| `journal.ps1` | `C:\Users\<user>\.local\bin\win-health\journal.ps1` | состояние: открытые/закрытые пункты, хронология, сводка `STATUS.md` |
| отчёты | `C:\Users\<user>\.local\state\win-health\audit-*.md`, `drivers-*.md`, `cleanup-*.md` | результаты прогонов |
| Sigcheck | `C:\Users\<user>\Tools\win-health\sysinternals\sigcheck64.exe` | подписи и версии драйверов |
| Autoruns | `...\sysinternals\autorunsc64.exe` | автозапуск: службы, задачи, расширения |
| Handle / Process Explorer | `...\sysinternals\handle64.exe`, `procexp64.exe` | кто держит файл/порт, дерево процессов |
| TCPView | `...\sysinternals\tcpview64.exe` | соединения по процессам |
| RAPR (Driver Store Explorer) | `C:\Users\<user>\Tools\win-health\rapr\Rapr.exe` | GUI: старые пакеты драйверов, размер DriverStore |
| LibreHardwareMonitor | `C:\Users\<user>\Tools\win-health\lhm\LibreHardwareMonitor.exe` | температуры, напряжения, частоты, вентиляторы |

Встроенное, что всегда под рукой: `Get-WinEvent`, `Get-CimInstance Win32_*`, `pnputil`, `dism`, `sfc`, `chkdsk`, `powercfg /energy`, `vssadmin`, `wevtutil`, `Get-StorageReliabilityCounter`, Driver Verifier (`verifier`).

Администратор нужен только для: `vssadmin`, `dism /AnalyzeComponentStore`, `sfc`, `chkdsk`, SMART через `Get-StorageReliabilityCounter`, `verifier`. Всё остальное работает без UAC.

## Журнал и преемственность

Навык обязан помнить, что уже сделано: пользователь не должен начинать с нуля.

Источник истины — `C:\Users\<user>\.local\state\win-health`:

| Файл | Роль |
|---|---|
| `state.json` | инварианты хоста, открытые и закрытые пункты |
| `journal.md` | append-only хронология сессий |
| `STATUS.md` | сводка, пересобирается скриптом |

Правила:

1. **В начале задачи** — `journal.ps1 -Action show` (или прочитать `STATUS.md`). Опирайся на `evidence` открытых пунктов и не повторяй закрытые проверки.
2. **В конце задачи** — `-Action session -Text "..."` с блоком: что проверено, что найдено, что сделано, что осталось.
3. **Новая находка** — `-Action add -Title ... -Next ... -Severity high|med|low`. Перед добавлением проверь, нет ли уже такого пункта.
4. **Закрытие** — только при подтверждённом результате: `-Action done -Id WH-xxx -Result "чем подтверждено"`.
5. **ID не переиспользуются**, формат `WH-###`.
6. `state.json` руками не править: только через скрипт. Ручная правка ломает JSON на обратных слешах в путях.
7. В отчёте пользователю первым делом называй `STATUS.md`: сколько открыто, что именно.

## Порядок разбора

1. **Снимок.** `audit.ps1 -Days 30`. Не начинай с догадок — сначала факты за окно времени.
2. **Классифицируй находки** по трём корзинам: сбой (BSOD/WHEA/41/6008), деградация (ошибки драйверов, служб, дисков), шум (DCOM 10010, BTHUSB 5, повторяющиеся предупреждения).
3. **Сбои — в первую очередь.** Для `Kernel-Power 41` смотри `BugcheckCode`: `0` = зависание/питание, не BSOD. Для bugcheck ищи дамп в `MinidumpDir` и `MEMORY.DMP`.
4. **Драйверы.** `drivers.ps1`, затем проблемные устройства с кодом проблемы. Код 10/43/28 — переустановка драйвера вендора, не «чистка».
5. **Ресурсы.** Подкачка/commit, ОЗУ (частота против заявленной), диски (HealthStatus, SMART), температуры под нагрузкой.
6. **Гипотеза → проверка.** Одна гипотеза — одна проверка. Не меняй два параметра сразу.
7. **План.** Приоритет: сначала то, что мешает собирать доказательства (дампы, журналы), потом стабильность, потом производительность.

## Команды

```powershell
# полный снимок за 30 дней
pwsh -File C:\Users\<user>\.local\bin\win-health\audit.ps1 -Days 30

# драйверы и Driver Store
pwsh -File C:\Users\<user>\.local\bin\win-health\drivers.ps1 -OlderThanYears 2

# замер очистки (ничего не удаляет)
pwsh -File C:\Users\<user>\.local\bin\win-health\cleanup-audit.ps1

# состояние: что сделано и что осталось
pwsh -File C:\Users\<user>\.local\bin\win-health\journal.ps1 -Action show

# записать сессию в хронологию
pwsh -File C:\Users\<user>\.local\bin\win-health\journal.ps1 -Action session -Text "Проверено: ...; Сделано: ...; Осталось: ..."

# новая находка и закрытие
pwsh -File C:\Users\<user>\.local\bin\win-health\journal.ps1 -Action add -Title "..." -Next "..." -Severity med
pwsh -File C:\Users\<user>\.local\bin\win-health\journal.ps1 -Action update -Id WH-009 -Next "новый шаг"
pwsh -File C:\Users\<user>\.local\bin\win-health\journal.ps1 -Action done -Id WH-005 -Result "чем подтверждено"
```

```powershell
# подписи драйверов
& C:\Users\<user>\Tools\win-health\sysinternals\sigcheck64.exe -nobanner -q -e -s C:\Windows\System32\drivers

# автозапуск в CSV
& C:\Users\<user>\Tools\win-health\sysinternals\autorunsc64.exe -accepteula -a * -h -s -nobanner -o csv

# кто держит файл
& C:\Users\<user>\Tools\win-health\sysinternals\handle64.exe "C:\path\file"

# драйверы в Store и устройства
pnputil /enum-drivers
pnputil /enum-devices /problem
```

```powershell
# энергопотребление и сон (нужен админ)
powercfg /energy /output $env:TEMP\energy.html
powercfg /sleepstudy /output $env:TEMP\sleep.html
```

## Расшифровки

**События:**

| Источник / Id | Смысл |
|---|---|
| Kernel-Power 41 | некорректное завершение; `BugcheckCode=0` — зависание/питание, не BSOD |
| WER-SystemErrorReporting 1001 | bugcheck с кодом и параметрами |
| EventLog 6008 | предыдущее завершение было неожиданным |
| volmgr 46 | не удалось инициализировать аварийный дамп (нет подкачки/места) |
| volmgr 162 | дамп успешно создан |
| BTHUSB 5 | Bluetooth-адаптер не выполнил HCI-команду |
| Hyper-V-VmSwitch 15 | сбой конфигурации виртуального коммутатора |
| 7000/7023/7031/7034 | служба не запустилась / упала / завершилась аварийно |
| Diagnostics-Performance 100–110 | время загрузки и виновники задержек |
| WindowsUpdateClient 19 / 20 | обновление установлено / ошибка установки |
| Ntfs 55 / 98 / 140 | повреждение ФС / ошибка записи в журнал |
| volsnap 33 / 36 | теневая копия удалена, не хватило места |

**Коды проблем устройств (Device Manager):** 1 — не настроено, 3 — нет драйвера/повреждён, 10 — не запускается, 12 — не хватает ресурсов, 18 — переустановить драйверы, 28 — драйвер не установлен, 31 — не удалось загрузить драйвер, 39 — повреждён драйвер, 43 — устройство сообщило о сбое, 52 — не проверена подпись.

## Ограничения

- `Get-Counter` на русской Windows не принимает английские имена счётчиков — используй `Win32_PerfRawData_*` или локализованные пути.
- Вывод консоли в кириллице ломается без `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`.
- Без администратора: нет SMART, `vssadmin`, `dism`, `sfc`, части WMI-счётчиков.
- Дампы без символов дают только код bugcheck; для стека нужен WinDbg и `!analyze -v`.
- Журнал System имеет предел (обычно 20 МБ) и ротацию: «ошибка при каждом запуске» может быть видна только за последние недели. Всегда указывай фактическое покрытие журнала.

## Отчёт

Указывай: окно времени и покрытие журнала, источник каждого факта (event id, путь, значение реестра), отдельно — что осталось неподтверждённым. Не называй причину, пока нет проверки. Формат: находка → доказательство → следствие → что делать.

## Безопасность

- Не отключай службы, защиту и обновления «для скорости» без доказанной причины.
- Не удаляй `pagefile.sys`, `hiberfil.sys`, `WinSxS` и содержимое `C:\Windows\Installer` вручную.
- Очистка — только по классу `safe` и только после подтверждения; `review` — с объяснением риска; `keep` — не трогать.
- Перед изменением конфигурации фиксируй исходное состояние, чтобы был откат.

## Готовые сторонние решения (только вручную)

| Решение | Репозиторий | Для чего | Риск |
|---|---|---|---|
| WinUtil | `ChrisTitusTech/winutil` | установка софта, твики, «Fix» | высокий: меняет систему пачкой |
| Win11Debloat | `Raphire/Win11Debloat` | удаление встроенных приложений и телеметрии | средний: необратимо для приложений |
| Optimizer | `hellzerg/optimizer` | приватность и производительность | высокий: реестр и службы |
| Sophia Script | `farag2/Sophia-Script-for-Windows` | тонкая настройка | средний: нужен разбор пресета |
| BleachBit | `bleachbit/bleachbit` | очистка кэшей и логов | низкий при точечном выборе |
| Driver Store Explorer | `lostindark/DriverStoreExplorer` | старые пакеты драйверов | средний: удалять только неиспользуемые |

Эти инструменты запускает пользователь. Навык может подготовить список целей и объяснить последствия, но не нажимает «применить».
