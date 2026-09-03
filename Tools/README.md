# DamageLife Companion Updater

Optional Windows helper for DamageLife 1.3.4.14+.

## What it does

- checks the project's latest GitHub Release over HTTPS;
- compares installed and latest versions;
- writes only `DamageLifeUpdateCache.lua`;
- lets the addon display the result in `/dl`;
- never silently replaces addon files.

## Quick start

Run `Start-DamageLife.bat` before starting WoW.

For periodic checks:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\DamageLifeUpdater.ps1 -Watch
```

## Design

```text
GitHub → Companion → UpdateCache.lua → DamageLife UpdateChecker → UI
```

The companion is deliberately separate from the addon because standard WoW 3.3.5a addon Lua cannot be treated as a general-purpose HTTP/file client.
