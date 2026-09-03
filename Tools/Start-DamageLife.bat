@echo off
setlocal
set "SCRIPT=%~dp0DamageLifeUpdater.ps1"
set "WOW_EXE="

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"

if not "%WOW_EXE%"=="" (
    start "World of Warcraft" "%WOW_EXE%"
)

echo.
echo DamageLife update cache refreshed.
echo Start WoW normally. DamageLife will display the cached GitHub status in /dl.
endlocal
