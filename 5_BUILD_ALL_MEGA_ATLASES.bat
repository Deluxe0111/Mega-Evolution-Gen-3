@echo off
setlocal
cd /d "%~dp0"
echo ===================================================
echo  Mega Evolution Gen 3 - Full 98-form atlas build
echo ===================================================
echo.
echo This generates PNG atlas pages and animation indexes.
echo It does not modify the original EBDX sprites.
echo.

where py >nul 2>nul
if not errorlevel 1 (
  py -3 -m pip install --only-binary=:all: Pillow==13.0.0
  if errorlevel 1 goto fail
  py -3 tools\build_mega_atlas.py
) else (
  python -m pip install --only-binary=:all: Pillow==13.0.0
  if errorlevel 1 goto fail
  python tools\build_mega_atlas.py
)
if errorlevel 1 goto fail
echo.
echo SUCCESS: All 98 Mega forms were processed.
echo Atlas pages: assets\runtime\atlas\
echo Animation indexes: assets\runtime\mega_atlas_index.json and mega_atlas_index.lua
echo Geometry report: reports\mega_sheet_geometry.csv
echo.
echo The atlas data is NOT yet hooked into Gen1Recomp battles.
pause
exit /b 0
:fail
echo.
echo BUILD FAILED. Review the error above.
echo If Pillow installation fails, use Python 3.11-3.15.
echo If a sprite is missing or malformed, see reports\mega_sheet_geometry.csv.
pause
exit /b 1
