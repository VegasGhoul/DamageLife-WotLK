# DamageLife — Automatic Update Detection

## Goal

DamageLife should be able to tell the player that a newer GitHub Release exists without requiring a manual visit to GitHub just to perform the check.

## Architecture

```text
                         HTTPS
                           │
                           ▼
                 GitHub Releases API
                           │
                           ▼
              DamageLife Companion
                           │
                    data-only cache
                           │
                           ▼
             DamageLifeUpdateCache.lua
                           │
                           ▼
                  UpdateChecker.lua
                           │
                           ▼
                     DamageLife UI
```

## Why an external component is required

WoW 3.3.5a addon Lua is sandboxed. The addon cannot rely on arbitrary TCP/TLS sockets or arbitrary filesystem access. A high-level Lua HTTP library therefore cannot simply be dropped into an addon and expected to work: libraries such as LuaSocket require capabilities that the addon sandbox does not expose.

The companion performs the network operation outside the game process and writes a small, controlled Lua data file. DamageLife only reads that data file.

## Security model

The cache contains data only:

- latest version;
- release name;
- release URL;
- optional ZIP asset URL;
- timestamp;
- comparison result.

The companion does not copy GitHub-provided Lua into the addon and does not execute release content.

## Installation model

The companion detects updates. It does not silently replace the installed addon.

This is intentional: a release remains a user-controlled installation step.

## Current implementation

`Tools/DamageLifeUpdater.ps1`:

1. reads the installed version from `DamageLife.toc`;
2. requests `/releases/latest` from the project's GitHub repository;
3. compares the release version with the installed version;
4. writes `DamageLifeUpdateCache.lua`;
5. reports the result.

`Tools/Start-DamageLife.bat` provides a simple Windows entry point.

## In-game behaviour

At addon load, `UpdateChecker.lua` reads the cache and the **О проекте → GitHub / обновления** panel displays the known status.

If the companion is not installed/running, DamageLife still works normally and simply keeps the last bundled/cache state.

## Important limitation

A pure addon-only implementation that performs a live HTTPS request from standard WoW 3.3.5a cannot be made reliable. A true live in-game request would require a modified client/extension that explicitly exposes a network bridge to Lua. That is a different project boundary and is intentionally not hidden behind a fake Lua HTTP library.
