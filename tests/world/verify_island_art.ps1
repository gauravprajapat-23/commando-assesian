# ISLAND-ART-04 — Windows Godot locator and world regression gate.
# Usage: powershell -ExecutionPolicy Bypass -File .\tests\world\verify_island_art.ps1
# Optional: -GodotExe "C:\Godot\Godot_v4.7.2-stable_win64.exe"
param([string]$GodotExe = "")

$ErrorActionPreference = "Stop"
Push-Location (Resolve-Path (Join-Path $PSScriptRoot "..\.."))
try {
    if (-not $GodotExe) {
        $cmd = Get-Command godot -ErrorAction SilentlyContinue
        if ($cmd) { $GodotExe = $cmd.Source }
    }
    if (-not $GodotExe) {
        $folders = @("C:\Godot", "$env:USERPROFILE\Downloads", "$env:LOCALAPPDATA\Programs")
        foreach ($folder in $folders) {
            if (-not (Test-Path $folder)) { continue }
            $match = Get-ChildItem -Path $folder -File -Recurse -Filter "*Godot*.exe" -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notmatch 'console' } | Select-Object -First 1
            if ($match) { $GodotExe = $match.FullName; break }
        }
    }
    if (-not $GodotExe -or -not (Test-Path $GodotExe)) {
        throw "Godot executable missing. Download https://godotengine.org/download/windows/ or pass -GodotExe <path>."
    }
    Write-Host "Godot: $GodotExe"
    & $GodotExe --version
    # Some Windows GUI-subsystem Godot builds print --version but return
    # a nonzero shell code. Treat this as diagnostic, not test evidence.
    # The editor import and startup below are the actual hard gates.
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Godot --version returned exit code $LASTEXITCODE. Continuing to import for a definitive engine result."
    }
    & $GodotExe --headless --editor --path . --import
    if ($LASTEXITCODE -ne 0) { throw "Godot editor import failed" }
    & $GodotExe --headless --path . --quit-after 3
    if ($LASTEXITCODE -ne 0) { throw "Godot startup smoke failed" }

    $tests = @(
        "res://tests/world/island_01_contract.gd",
        "res://tests/world/ocean_atmosphere_test.gd",
        "res://tests/player/test_commando.gd",
        "res://tests/enemies/guard_ai_test.gd",
        "res://tests/missions/mission_controller_test.gd",
        "res://tests/ui/mission_hud_test.gd",
        "res://tests/integration/island_01_flow.gd"
    )
    foreach ($test in $tests) {
        Write-Host "RUN $test"
        & $GodotExe --headless --fixed-fps 60 --path . --script $test
        if ($LASTEXITCODE -ne 0) { throw "Godot test failed: $test (exit $LASTEXITCODE)" }
    }
    Write-Host "PASS: import, smoke and all available Island 01 suites"
}
finally { Pop-Location }
