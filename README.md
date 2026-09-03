# ⚔️ DamageLife — WoW 3.3.5a PvP / DPS

> Тактический PvP/DPS-аддон для World of Warcraft 3.3.5a, созданный с упором на анализ целей, давление, burst, control, execute и боевые уведомления.

**Текущая версия:** `1.3.4.14`  
**WoW:** `3.3.5a / Interface 30300`  
**Команда:** `/dl`

---

## ✨ Возможности

- 🎯 интеллектуальная оценка целей и Target Windows;
- 💥 Burst / Execute / Control / Defensive tracking;
- 🔄 SWITCH — рекомендация смены цели с причиной;
- ⚡ боевые уведомления, звуки и голосовые пакеты;
- 🧠 Combat Advisor и анализ боевой ситуации;
- 🏹 определение классов и специализаций;
- 🏟️ BG Timers и тактические события для полей боя;
- 🎨 собственный интерфейс DamageLife с текстурами и тематическими элементами;
- 👤 профили и настройки для персонажей;
- 🔊 Gong / Voice режимы уведомлений.

---

## 🔄 Система проверки обновлений

Начиная с `1.3.4.14`, проект использует двухуровневую архитектуру:

```text
GitHub Releases API
        ↓
DamageLife Companion
        ↓
DamageLifeUpdateCache.lua
        ↓
UpdateChecker.lua
        ↓
DamageLife UI
```

### Почему не HTTP напрямую из аддона?

Обычный WoW 3.3.5a addon Lua работает в sandbox и не получает произвольный HTTPS/file I/O API. Поэтому сетевую часть нельзя надёжно реализовать только `.lua`-файлами.

DamageLife решает это через **небольшой внешний companion**. Он выполняет HTTPS-запрос к GitHub Releases API, сравнивает версии и передаёт в аддон только безопасные данные о Release.

### Что делает companion

- автоматически проверяет GitHub Releases;
- определяет установленную и последнюю версии;
- сохраняет результат в `DamageLifeUpdateCache.lua`;
- не выполняет код, полученный из GitHub;
- не заменяет файлы аддона автоматически;
- не требует от пользователя вручную открывать GitHub для самой проверки.

Подробнее: [`Tools/README.md`](Tools/README.md) и [`docs/AUTO_UPDATE.md`](docs/AUTO_UPDATE.md).

> **Важно:** автоматическое обнаружение обновления ≠ бесшумная установка. Пользователь сам решает, когда устанавливать новую версию аддона.

---

## 📦 Установка

1. Скачать Release.
2. Распаковать папку `DamageLife` в `Interface/AddOns/`.
3. При использовании автоматической проверки запустить `Tools/Start-DamageLife.bat` перед WoW.
4. Запустить WoW.
5. Открыть `/dl` → **О проекте** → **GitHub / обновления**.

---

## 🧪 Статус проекта

Проект находится в активной разработке и тестируется на WoW 3.3.5a.

При сообщении об ошибке желательно указать:

- версию DamageLife;
- название поля боя/арены или режима;
- Lua error целиком;
- что происходило непосредственно перед ошибкой.

---

## 🗂️ Структура

```text
DamageLife/
├── DamageLife.toc
├── DamageLife.lua
├── Settings.lua
├── CombatEngine.lua
├── CombatAdvisor.lua
├── DPSCombat.lua
├── BGTimers.lua
├── SpecDatabase.lua
├── SpecDetection.lua
├── AbilitySounds.lua
├── ControlAlerts.lua
├── CompletionCore.lua
├── Profiles.lua
├── Localization.lua
├── Theme.lua
├── DamageLifeHTTP.lua
├── DamageLifeUpdateCache.lua
├── UpdateChecker.lua
├── Modules/
├── Textures/
├── Sounds/
└── Tools/
    ├── DamageLifeUpdater.ps1
    ├── Start-DamageLife.bat
    └── README.md
```

---

## 📜 Версии

Официальные версии публикуются через **GitHub Releases**.

- `1.3.4.14` — GitHub Update System + Companion backend.
- `1.3.4.13` — GitHub integration, UI fixes и SWITCH text fix.

---

## 👤 Автор

**Vegasy**

GitHub: `VegasGhoul`

---

## ⚠️ Дисклеймер

DamageLife — пользовательский addon для WoW 3.3.5a. Проект не связан с Blizzard Entertainment.
