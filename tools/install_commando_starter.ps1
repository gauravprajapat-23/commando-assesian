# PLAYER-ANIM-03 — Install a real rigged starter soldier into Godot.
# Source: official three.js examples Soldier.glb (Mixamo-derived sample).
# No third-party Godot addons, Blender, npm, or Python required.
param(
    [switch]$Force,
    [string]$SourceUrl = "https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/Soldier.glb"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$targetDir = Join-Path $projectRoot "assets\characters"
$target = Join-Path $targetDir "commando.glb"
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
if ((Test-Path $target) -and -not $Force) {
    throw "Character already exists: $target. To replace it deliberately, re-run with -Force."
}

$temp = Join-Path $targetDir ("commando.download-" + [guid]::NewGuid().ToString("N") + ".glb")
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host "Downloading the rigged sample Soldier from three.js..."
    Invoke-WebRequest -Uri $SourceUrl -OutFile $temp -UseBasicParsing -MaximumRedirection 5
    $file = [System.IO.File]::OpenRead($temp)
    try {
        $reader = New-Object System.IO.BinaryReader($file)
        $magic = $reader.ReadUInt32()
        $version = $reader.ReadUInt32()
        $length = $reader.ReadUInt32()
        if ($magic -ne 0x46546C67 -or $version -ne 2 -or $length -ne $file.Length) {
            throw "Invalid GLB v2 header or mismatched file length"
        }
        $jsonLength = $reader.ReadUInt32()
        $jsonType = $reader.ReadUInt32()
        if ($jsonType -ne 0x4E4F534A -or $jsonLength -le 0 -or $jsonLength -gt (16MB)) {
            throw "Invalid GLB JSON chunk"
        }
        $jsonBytes = $reader.ReadBytes($jsonLength)
        $asset = [Text.Encoding]::UTF8.GetString($jsonBytes).TrimEnd([char[]]@([char]0, [char]32)) | ConvertFrom-Json
        if (@($asset.skins).Count -lt 1 -or @($asset.animations).Count -lt 1 -or @($asset.meshes).Count -lt 1) {
            throw "The source is not a skinned mesh with embedded animations"
        }
        $clips = @($asset.animations | ForEach-Object { $_.name })
        Write-Host ("Validated: {0} skin(s), {1} meshes, animations: {2}" -f @($asset.skins).Count, @($asset.meshes).Count, ($clips -join ", "))
        if (-not ($clips | Where-Object { $_ -match '(?i)idle' }) -or -not ($clips | Where-Object { $_ -match '(?i)walk' })) {
            throw "Expected Idle and Walk animations are missing: $($clips -join ', ')"
        }
    }
    finally {
        $file.Dispose()
    }
    $hash = (Get-FileHash -LiteralPath $temp -Algorithm SHA256).Hash
    if ((Test-Path $target) -and $Force) { Remove-Item -LiteralPath $target -Force }
    Move-Item -LiteralPath $temp -Destination $target
    $manifest = @"
PLAYER-ANIM-03 external sample asset
Downloaded from: $SourceUrl
SHA256: $hash
Animation clips: $($clips -join ', ')
Model provenance: Mixamo-derived Soldier example distributed in three.js.
See official three.js model and example pages; respect applicable model and texture terms.
This is a starter skinned soldier with locomotion clips, NOT a photorealistic modern commando.
"@
    Set-Content -Path (Join-Path $targetDir "commando.asset-source.txt") -Value $manifest -Encoding UTF8
    Write-Host "PASS: Installed $target"
    Write-Host "Next: run Godot editor import, then PLAYER-ANIM-03 tests."
}
finally {
    if (Test-Path $temp) { Remove-Item $temp -Force }
}
