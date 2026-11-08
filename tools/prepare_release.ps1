# Prepare a versioned, Modkit-validated Mega Evolution player ZIP.
# Run from the repository root:
#   powershell -NoProfile -File .\tools\prepare_release.ps1
#
# No release is uploaded by this script. Test the resulting ZIP before publishing.

[CmdletBinding()]
param(
    [string]$EnginePath = "",
    [string]$LuaJITPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
if (-not $EnginePath) {
    $EnginePath = Join-Path (Split-Path -Parent $root) "gen1recomp"
}
if (-not (Test-Path -LiteralPath (Join-Path $EnginePath "tools\modkit.py") -PathType Leaf)) {
    throw "Gen1Recomp Modkit not found at '$EnginePath'. Pass -EnginePath with the engine repository path."
}
$engine = (Resolve-Path -LiteralPath $EnginePath).Path

if (-not $LuaJITPath) {
    if ($env:MODKIT_LUAJIT) {
        $LuaJITPath = $env:MODKIT_LUAJIT
    } else {
        $LuaJITPath = "C:\msys64\ucrt64\bin\luajit.exe"
    }
}
if (-not (Test-Path -LiteralPath $LuaJITPath -PathType Leaf)) {
    throw "LuaJIT not found at '$LuaJITPath'. Pass -LuaJITPath or set MODKIT_LUAJIT."
}
$env:MODKIT_LUAJIT = (Resolve-Path -LiteralPath $LuaJITPath).Path

$manifestPath = Join-Path $root "manifest.json"
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.id -ne "mega-evolution-gen3" -or $manifest.version -ne "1.0.0") {
    throw "This release script requires mega-evolution-gen3 manifest version 1.0.0."
}

$zipName = "mega-evolution-gen3-v1.0.0.zip"
$distDir = Join-Path $root "dist"
$preview = Join-Path $distDir "mega-evolution-gen3-v1.0.0-private-preview.zip"
$validated = Join-Path $distDir $zipName
$stage = Join-Path ([System.IO.Path]::GetTempPath()) ("mega-modkit-" + [guid]::NewGuid().ToString("N"))

function Invoke-PythonChecked {
    param([string]$WorkingDirectory, [string[]]$Arguments)
    Push-Location -LiteralPath $WorkingDirectory
    try {
        & py @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Python command failed (exit $LASTEXITCODE): py $($Arguments -join ' ')"
        }
    } finally {
        Pop-Location
    }
}

try {
    Write-Host "Checking Mega Evolution source inventory and documentation..."
    Invoke-PythonChecked $root @("tests\check_project.py")
    Invoke-PythonChecked $root @("tests\check_docs.py")
    Invoke-PythonChecked $root @("tools\package_release.py", "--check")

    Write-Host "Staging the runtime-only preview archive..."
    Invoke-PythonChecked $root @("tools\package_release.py", "--private-preview")
    if (-not (Test-Path -LiteralPath $preview -PathType Leaf)) {
        throw "Expected preview ZIP not found: $preview"
    }

    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    Expand-Archive -LiteralPath $preview -DestinationPath $stage
    foreach ($required in @("manifest.json", "main.lua", "CREDITS.md", "DIFFERENCES.md")) {
        if (-not (Test-Path -LiteralPath (Join-Path $stage $required) -PathType Leaf)) {
            throw "The staged ZIP is missing $required at the archive root."
        }
    }

    Write-Host "Running all Gen1Recomp Modkit gates against the staged player files..."
    Invoke-PythonChecked $engine @("tools\modkit.py", "validate", $stage, "--strict")
    Invoke-PythonChecked $engine @("tools\modkit.py", "lint", $stage)
    Invoke-PythonChecked $engine @("tools\modkit.py", "gen3check", $stage, "--strict")

    Write-Host "Building the versioned Modkit-validated ZIP..."
    if (Test-Path -LiteralPath $validated) {
        Remove-Item -LiteralPath $validated -Force
    }
    Invoke-PythonChecked $engine @("tools\modkit.py", "pack", $stage, "-o", $validated)

    if (-not (Test-Path -LiteralPath $validated -PathType Leaf)) {
        throw "Modkit reported success but the validated release ZIP was not found."
    }

    $digest = (Get-FileHash -LiteralPath $validated -Algorithm SHA256).Hash.ToLowerInvariant()
    $checksum = Join-Path $distDir ($zipName + ".sha256")
    Set-Content -LiteralPath $checksum -Encoding ascii -Value ("$digest  $zipName")

    Write-Host ""
    Write-Host "SUCCESS: Release candidate generated and validated."
    Write-Host "ZIP:      $validated"
    Write-Host "SHA-256:  $checksum"
    Write-Host "Tag:      v1.0.0 (not created by this script)"
    Write-Host "Next: install-test the ZIP and attach it to the v1.0.0 GitHub release."
} finally {
    if (Test-Path -LiteralPath $stage) {
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
}
