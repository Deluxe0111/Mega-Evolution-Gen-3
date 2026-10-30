@echo off
cd /d "%~dp0"
where py >nul 2>nul
if not errorlevel 1 (
  py -3 tools\validate_assets.py --root assets/source/ebdx
) else (
  python tools\validate_assets.py --root assets/source/ebdx
)
pause
