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
    # Prefer Windows console build: native PowerShell invocation may return
    # before a GUI-subsystem Godot process finishes, leaving LASTEXITCODE null.
    $consoleExe = $GodotExe -replace '(?i)_win64\.exe$', '_win64_console.exe'
    if ((Test-Path $consoleExe) -and ($consoleExe -ne $GodotExe)) {
        $GodotExe = $consoleExe
        Write-Host "Using synchronous console build: $GodotExe"
    }

    function Invoke-GodotChecked {
        param(
            [string[]]$Arguments,
            [string]$Label
        )
        # Start-Process -Wait -PassThru works for both GUI and console builds.
        # Logs are captured to distinct files and replayed after completion.
        $stdout = [System.IO.Path]::GetTempFileName()
        $stderr = [System.IO.Path]::GetTempFileName()
        try {
            $process = Start-Process -FilePath $GodotExe `
                -ArgumentList $Arguments `
                -WorkingDirectory (Get-Location).Path `
                -RedirectStandardOutput $stdout `
                -RedirectStandardError $stderr `
                -Wait -PassThru
            $outText = Get-Content -LiteralPath $stdout -Raw -ErrorAction SilentlyContinue
            $errText = Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue
            if ($outText) { Write-Host $outText }
            if ($errText) { Write-Host $errText }
            Write-Host "$Label exit code: $($process.ExitCode)"
            if ($process.ExitCode -ne 0) {
                throw "$Label failed with exit code $($process.ExitCode)"
            }
            if ($errText -match '(?m)^\s*(SCRIPT ERROR|ERROR):') {
                throw "$Label reported Godot errors. Inspect output above."
            }
        }
        finally {
            Remove-Item -LiteralPath $stdout,$stderr -Force -ErrorAction SilentlyContinue
        }
    }

    Invoke-GodotChecked -Arguments @("--version") -Label "Godot version"
    Invoke-GodotChecked -Arguments @("--headless","--editor","--path",".","--import") -Label "Godot import"
    Invoke-GodotChecked -Arguments @("--headless","--path",".","--quit-after","3") -Label "Godot startup"

    $tests = @(
        "res://tests/world/island_01_contract.gd",
        "res://tests/world/world_preview_camera_test.gd",
        "res://tests/world/coastal_terrain_test.gd",
        "res://tests/world/jungle_foliage_test.gd",
        "res://tests/world/military_compound_test.gd",
        "res://tests/world/ocean_atmosphere_test.gd",
        "res://tests/player/test_commando.gd",
        "res://tests/player/commando_visual_test.gd",
        "res://tests/enemies/guard_ai_test.gd",
        "res://tests/missions/mission_controller_test.gd",
        "res://tests/ui/mission_hud_test.gd",
        "res://tests/integration/island_01_flow.gd"
    )
    foreach ($test in $tests) {
        Write-Host "RUN $test"
        Invoke-GodotChecked -Arguments @("--headless","--fixed-fps","60","--path",".","--script",$test) -Label $test
    }
    Write-Host "PASS: import, smoke and all available Island 01 suites"
}
finally { Pop-Location }
