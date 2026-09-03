# DamageLife Changelog

## 1.3.4.14 — Optimized Update Checker

### Added

- Лёгкий интерфейс для асинхронного update backend.
- Сохранение последнего результата в SavedVariables.
- Защита от повторной проверки чаще одного раза в 24 часа.
- Защита от проверки во время боя и БГ/арены.
- Документация архитектуры Update Checker.

### Changed

- Убраны пользовательские BAT/PS1/EXE-компоненты.
- Убран постоянный polling.
- Убран `OnUpdate`-таймер для обновлений.
- Синхронные HTTP-вызовы не используются.
- Update Checker не загружает ZIP и не заменяет файлы аддона.
- `/dl → О проекте → GitHub / обновления` показывает только достоверно полученные данные.

### Important

Стандартный WoW 3.3.5a addon sandbox не предоставляет произвольный HTTPS API. Поэтому реальный интернет-запрос возможен только при наличии разрешённого асинхронного host/relay backend. Без него Update Checker не создаёт фоновой сетевой нагрузки.

## 1.3.4.13

- GitHub integration preparation.
- Update panel UI fixes.
- SWITCH text visibility fix.
