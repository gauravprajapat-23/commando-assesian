# PLAYER-ANIM-03B: explicitly install a rigged military soldier.
# Source repository credits "FREE [Military Soldier] RIGGED" by BAMEN under CC BY 4.0.
# The installer records provenance; game distribution must include attribution.
param(
    [switch]$ReplaceExisting,
    [string]$SourceUrl = "https://raw.githubusercontent.com/cktang88/3d-fps/main/public/assets/models/characters/soldier.glb"
)
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$dir = Join-Path $root "assets\characters"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$target = Join-Path $dir "commando.glb"
$temp = Join-Path $dir ("soldier-" + [guid]::NewGuid().ToString("N") + ".download")
if ((Test-Path $target) -and -not $ReplaceExisting) {
    throw "Existing commando.glb found. To preserve it, nothing was changed. Re-run with -ReplaceExisting to back it up and install the military rig."
}
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $SourceUrl -OutFile $temp -MaximumRedirection 5 -UseBasicParsing
    $stream = [IO.File]::OpenRead($temp)
    try {
        $reader = [IO.BinaryReader]::new($stream)
        if ($reader.ReadUInt32() -ne 0x46546C67) { throw "Not a GLB file" }
        if ($reader.ReadUInt32() -ne 2) { throw "Requires GLB v2" }
        if ($reader.ReadUInt32() -ne $stream.Length) { throw "GLB file length mismatch" }
        $jsonLength = $reader.ReadUInt32()
        if ($reader.ReadUInt32() -ne 0x4e4f534a -or $jsonLength -le 0 -or $jsonLength -gt 16777216) {
            throw "Invalid GLB JSON chunk"
        }
        $bytes = $reader.ReadBytes($jsonLength)
        $gltf = ([Text.Encoding]::UTF8.GetString($bytes)).TrimEnd([char[]]@([char]0, [char]32)) | ConvertFrom-Json
        if (@($gltf.skins).Count -lt 1 -or @($gltf.meshes).Count -lt 1 -or @($gltf.animations).Count -lt 1) {
            throw "No skeleton, mesh, or embedded animation"
        }
        $clips = @($gltf.animations | ForEach-Object { [string]$_.name })
        Write-Host ("Validated GLB with {0} skins, {1} meshes, {2} animations" -f @($gltf.skins).Count, @($gltf.meshes).Count, $clips.Count)
        Write-Host ("Animation clips: " + ($clips -join ", "))
    } finally { $stream.Dispose() }
    $sha = (Get-FileHash -LiteralPath $temp -Algorithm SHA256).Hash
    if (Test-Path $target) {
        $backup = Join-Path $dir ("commando.backup-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".glb")
        Move-Item -LiteralPath $target -Destination $backup
        Write-Host ("Previous model backed up: " + $backup)
    }
    Move-Item -LiteralPath $temp -Destination $target
    $credit = @"
Third-party model: FREE [Military Soldier] RIGGED
Author: BAMEN
Original: https://sketchfab.com/3d-models/free-military-soldier-rigged-e9c56308a67d4a3db62e914fafa4d198
Licence: Creative Commons Attribution 4.0 (CC BY 4.0)
Licence text: https://creativecommons.org/licenses/by/4.0/
Downloaded derivative from: $SourceUrl
Derivative project: https://github.com/cktang88/3d-fps
SHA256 of installed file: $sha
Animation names: $($clips -join ", ")
Attribution and notice of modifications are required when distributing the game.
The upstream derivative may have modifications relative to the original asset.
"@
    Set-Content -LiteralPath (Join-Path $dir "MILITARY_SOLDIER_ATTRIBUTION.txt") -Value $credit -Encoding UTF8
    Write-Host "PASS PLAYER-ANIM-03B: Installed military soldier at $target"
    Write-Host "Import the model in Godot and run tests/player/commando_asset_test.gd."
} finally {
    if (Test-Path $temp) { Remove-Item -LiteralPath $temp -Force }
}
