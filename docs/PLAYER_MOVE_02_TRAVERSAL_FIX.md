# PLAYER-MOVE-02 — Island traversal / apparent player freeze

## Findings and changes

- The objective landmark's **solid mast was centered on the main northbound approach**, near x=0/z=-44. Its collision previously stopped an upright CharacterBody3D walking directly through the objective area. Moved the landmark to x=3.6 (flag follows) while keeping `ObjectivePoint` and mission detection at the original location.
- Player `CharacterBody3D.floor_snap_length` is now 0.25m to stabilize ground contact across slight height variations. This does not disable obstacle collisions.
- After 0.65s of near-zero horizontal displacement while moving against a solid collider, the controller logs `PLAYER MOVEMENT BLOCKED` with position and a collider path when available. On death, it logs `PLAYER DEFEATED`. Those are distinct causes for a perceived input freeze.
- New headless regression `res://tests/player/commando_traversal_test.gd` actually sprints from beach spawn z=37 past the objective approach z=-46 over the real island collision world, checking for unexpected stalls. No enemies are instantiated in this isolated test, so it diagnoses geometry and movement only.

## Expected gameplay boundaries

The outpost's **north wall at z=-54 is intentionally solid**; the shoreline also has finite world bounds. This patch does not make walls passable. Guard fire can bring health to zero, which intentionally disables movement. Check HUD HEALTH and mission state, and Godot's Output panel for the explicit diagnostic message.

## Windows verification

```powershell
cd "C:\Users\gauravp\Projects\commando-assesian"
git fetch origin
git pull --ff-only

$godot = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
& $godot --headless --editor --path . --import
& $godot --headless --fixed-fps 60 --path . --script res://tests/player/commando_traversal_test.gd

powershell -ExecutionPolicy Bypass -File .\tests\world\verify_island_art.ps1 -GodotExe "C:\Godot\Godot_v4.7.2-stable_win64.exe"
```

Then run the game, walk and sprint north from the beach in the central path, approach the objective, and check there is no stop at the old mast. Also verify guards and mission objective still function. If another stop occurs, copy the `PLAYER MOVEMENT BLOCKED` line and HEALTH number from HUD to distinguish actual collider from being killed. All changes remain on the feature branch; no merge.
