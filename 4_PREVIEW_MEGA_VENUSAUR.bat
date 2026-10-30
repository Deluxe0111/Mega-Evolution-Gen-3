@echo off
cd /d "%~dp0"
where py >nul 2>nul
if not errorlevel 1 (
  py -3 -m pip install Pillow==11.3.0
  if errorlevel 1 goto fail
  py -3 tools\build_mega_atlas.py --only mega_venusaur --preview
) else (
  python -m pip install Pillow==11.3.0
  if errorlevel 1 goto fail
  python tools\build_mega_atlas.py --only mega_venusaur --preview
)
if errorlevel 1 goto fail
echo.
echo Open assets\runtime\previews to inspect the animations.
pause
exit /b 0
:fail
echo Atlas preview failed. Review errors above.
pause
exit /b 1
