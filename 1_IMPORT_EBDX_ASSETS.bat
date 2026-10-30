@echo off
cd /d "%~dp0"
where py >nul 2>nul
if not errorlevel 1 (
  py -3 tools\extract_ebdx_megas.py --out assets/source/ebdx
) else (
  python tools\extract_ebdx_megas.py --out assets/source/ebdx
)
pause
