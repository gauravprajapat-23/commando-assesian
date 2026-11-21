# ISLAND-ART-05 integration candidate

Integrates draft PRs #18 terrain, #19 foliage, #20 compound, and #21 ocean onto isolated branch based on dev. All four _ready() visual subsystem initialization calls are retained. The old water-only box is replaced by the new ocean to avoid intersecting water planes. No main/dev changes.

## Windows Godot fix
The --version probe can print a valid version with a nonzero shell code on some Windows GUI builds. The test runner now warns for a nonzero version probe and proceeds to import/startup; all engine imports and test exit codes remain strict. Supply -GodotExe C:\\Godot\\Godot_v4.7.2-stable_win64.exe when needed.

## Tests
powershell -ExecutionPolicy Bypass -File .\\tests\\world\\verify_island_art.ps1 -GodotExe "C:\\Godot\\Godot_v4.7.2-stable_win64.exe"

The runner covers import, smoke, WORLD-001, four art-specific suites, player, enemy, missions, HUD and integration test.

## Known blockers
- Godot execution and visual rendered acceptance unverified.
- Exterior military tents and barracks have no collision; do not treat as release-ready.
- Potential mesh/art overlap and shoreline seams must be rendered and reviewed.
- Android export/performance and audio playback unverified.
- Local project.godot is modified on user's PC; preserve before switching branches.
- Do not auto-merge or bypass draft review gates.
