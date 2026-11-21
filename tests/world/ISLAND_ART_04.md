# ISLAND-ART-04 — Ocean, beach and atmosphere (GL Compatibility)

## Before running any gameplay tests: Windows command resolution
The reported error `godot : The term 'godot' is not recognized` occurs
**before** game code executes. It is not evidence of a GDScript failure.
Use the verified executable path; do not assume Godot is on PATH:

```powershell
cd "C:\Users\gauravp\Projects\commando-assesian"
powershell -ExecutionPolicy Bypass -File .\tests\world\verify_island_art.ps1 -GodotExe "C:\Godot\Godot_v4.7.2-stable_win64.exe"
```

Replace the path with the actual local filename. Without `-GodotExe`, the
script searches PATH, C:\Godot, Downloads, and LocalAppData\Programs. It stops
and returns nonzero upon a failed import, startup or test. Godot Windows binaries:
https://godotengine.org/download/windows/

## Scope
A native, renderer-safe ocean and atmosphere *prototype*:
- Low-poly animated ocean plane, built using PlaneMesh and a lightweight
  vertex shader; no compute shader, depth sampler, screen texture or addons.
- Three beach-side foam-colored strips for visual shoreline staging.
- WorldEnvironment: daylight background, ambient light, standard distance fog.
  **No volumetric fog**, which Compatibility does not support.
- One shadow-free directional sun.
- Named optional AmbientAudio player with no stream assigned; no sound is
  emitted until a properly licensed local audio asset is supplied.

All new geometry is visual-only. Existing WORLD-001 terrain, water blockout,
markers, collisions, objective triggers and guard LOS remain intact. Existing
water rectangle overlaps part of the new ocean plane intentionally to keep
the approved blockout visible; rendered visual review must assess water seams.

## Ownership and dependencies
Only `scripts/world/**` and `tests/world/**` changed. This branch starts
from `dev`, independent of still-draft PRs #18, #19 and #20.

Each milestone adds a separate `_ready()` call in
`scripts/world/island_01.gd`: when integrating, retain all calls,
and check for overlap and scene behavior:
- `CoastalTerrain` (#18)
- `JungleFoliage` (#19)
- `MilitaryCompound` (#20)
- `OceanAtmosphere` (#21 or assigned new PR number)

IMPORTANT: Do not blindly merge all four. Run each draft gate first; fix
geometry or performance regressions, then conduct a combined candidate test.

## Addon install decisions
**Mandatory external Godot addons: none** for ISLAND-ART-01..04.
Godot 4 itself is required.

Optional later:
1. Terrain3D: https://github.com/TokisanGames/Terrain3D
   Sculpt/paint terrain; match binary release with engine and platform.
2. ProtonScatter: https://github.com/HungryProton/scatter
   Editor scatter placement; evaluate the Godot 4 version before installation.
3. Godot-Ocean-Shader: https://github.com/immaculate-lift-studio/Godot-Ocean-Shader
   Water reference only: verify exact renderer support and licensing.
4. Kenney assets: https://kenney.nl/assets
5. Quaternius: https://quaternius.com/

Do not install several systems before basic tests pass. Asset licenses,
attribution, redistribution and Android export should be recorded before
committing downloaded assets.

## Acceptance gate
```powershell
powershell -ExecutionPolicy Bypass -File .\tests\world\verify_island_art.ps1
```
Manual checks: desktop GL Compatibility camera view, water seam, fog, shoreline,
mission traversal and extraction; test Android separately. No runtime claims
without actual Godot exit codes/logs. An empty `AmbientAudio` node is not
a working jungle sound system.
