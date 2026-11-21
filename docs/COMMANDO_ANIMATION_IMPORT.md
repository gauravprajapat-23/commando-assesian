# PLAYER-ANIM-03 — Installed soldier asset and import validation

## First playable imported soldier

For a reproducible first **skinned** model rather than the blocky procedural fallback, the branch includes a Windows installer for the three.js example Soldier GLB. It is a recognizable humanoid model with an actual skeleton and Idle/Walk/Run animation clips, **not a photorealistic military operator**. The original example identifies the model as Mixamo-derived; verify your use and redistribution rights for the underlying model before releasing your game. The installer deliberately does not commit or redistribute the binary.

The source is [official three.js Soldier.glb](https://github.com/mrdoob/three.js/blob/dev/examples/models/gltf/Soldier.glb), and [official example](https://github.com/mrdoob/three.js/blob/dev/examples/webgl_animation_walk.html). This can be replaced by a properly licensed high-quality rigged tactical soldier later.

**From PowerShell**:

```powershell
cd "C:\Users\gauravp\Projects\commando-assesian"
git switch fix/godot-windows-runner-addon-isolation
git fetch origin
git pull --ff-only

# Downloads model, validates GLB v2, skin + mesh + Idle/Walk animations,
# writes provenance + SHA256 record locally:
powershell -ExecutionPolicy Bypass -File .\tools\install_commando_starter.ps1

# Import the new asset with the exact local Godot build.
& "C:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --editor --path . --import

# Validate the actual imported skeleton and clips:
& "C:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/player/commando_asset_test.gd

# Then all 13+ gameplay/world suites:
powershell -ExecutionPolicy Bypass -File .\tests\world\verify_island_art.ps1 -GodotExe "C:\Godot\Godot_v4.7.2-stable_win64.exe"
```

Installer refuses to overwrite a local `commando.glb` unless explicitly given `-Force`, and creates `assets/characters/commando.asset-source.txt` with SHA256 and origin details. The downloaded binary is on your PC; it is **not present in GitHub** yet.

## Model placement and orientation

The player scene loads `res://assets/characters/commando.glb` automatically. Inspect `BodyVisual` in game. Its imported visuals support three exported parameters in `scripts/player/commando_visual.gd`: `imported_model_scale` (default 1), `imported_model_yaw_degrees` (default 180), `imported_model_vertical_offset` (default 0). Set these on `BodyVisual` in Godot Inspector for different models. Keep the physics collider and CameraYaw unchanged.

A `get_import_report()` method returns the model presence, skeleton bone count, recognized animation names, and current transform settings. If the GLB has no supported animation clips the procedural character remains the fallback.

## About retargeting the full tactical animation set

The current adapter plays embedded humanoid clips and maps common names. It does **not** magically retarget animations from a different skeleton to this one, and the three.js sample only establishes baseline Idle/Walk/Run. To add crouch, ADS, reload, fire and death, import clips **targeting the same skeleton** or use a compatible Godot Humanoid BoneMap / Blender retarget step and export one GLB with clips merged. Weapon grip and upper-body blending need a model-specific AnimationTree/IK setup; do not infer that these are verified until imported and visually tested.

For final realistic art, use a licensed textured tactical soldier with appropriate bone weights, a compatible rig, gear and weapons rather than the three.js starter. Test from front, rear and sides in Godot and keep frame rate reasonable on Intel UHD 630.

---

# PLAYER-ANIM-02 — Rigged soldier integration (Godot 4.7)

The player now has a visual animation adapter wired into the authoritative movement and combat controller. **A realistic character model is not included in the repository.** Without one, the native procedural tactical commando remains visible and uses lightweight motion for walking, running, aiming, reloading, firing and death.

## Install a rigged soldier model

1. Obtain a licensed **skinned and rigged** military soldier model that includes animation clips (ideally a single GLB with actions). Do not use a static mesh and expect it to animate.
2. Confirm the character is roughly **1.8 m tall**, faces **negative Z** and has its feet near local origin. Normalize model scale, pivot and rotation in your model tool before export. Check the texture license.
3. Save the file as `res://assets/characters/commando.glb`. The project uses Godot's built-in GLB importer and does **not** need Terrain3D, ProtonScatter or a native GDExtension.
4. In Godot Editor, wait for the import to complete, open the player scene and check `BodyVisual > ImportedCommando`. Review skinned mesh, Skeleton3D, AnimationPlayer and texture/material paths.
5. Press F5 and check all modes: idle, walk (WASD), sprint (Shift), crouch (Ctrl), aim (right mouse), fire (left mouse), reload (R) and death. F8 spectator mode is separate.

## Supported animation names

The adapter recursively searches the imported model for the first `AnimationPlayer`. The clips must use one of these case-insensitive names (or clear suffixes such as `Rig|Walking`):

| Game state | Accepted clip names |
|---|---|
| Idle | Idle, Breathing, Stand |
| Walk | Walk, Walking, Locomotion |
| Sprint | Run, Running, Sprint |
| Crouch | Crouch, Sneak, Crouched |
| Aim | Aim, Rifle_Idle, ADS |
| Fire | Fire, Shoot, Firing |
| Reload | Reload, Reloading |
| Death | Death, Die, Dying |

If a clip is absent the adapter uses the closest supported idle/walk state. It cannot generate skeletal animation data that does not exist in the GLB. A rig without any AnimationPlayer will display but remain static. Root-motion clips may cause sliding; prefer *in-place* clips because the CharacterBody3D controller owns physical movement. Avoid incompatible animation/skeleton packs without retargeting.

## Free legal animation resources to evaluate

- CC0 GLB humanoid animation example: https://github.com/Kinemiq/free-game-animations (35 animations on a common humanoid rig; includes locomotion, crouch, death). **This is an animation resource, not a realistic military soldier model.** Check bone compatibility before merging with another model.
- Rigged character model and skeleton may come from a separate artist. Animation retargeting, materials and additional clips for weapon aiming/reload may still be required.
- The default game remains fully usable without an external download.

## Verification

```powershell
cd "C:\Users\gauravp\Projects\commando-assesian"
git fetch origin
git pull --ff-only
powershell -ExecutionPolicy Bypass -File .\tests\world\verify_island_art.ps1 -GodotExe "C:\Godot\Godot_v4.7.2-stable_win64.exe"
```

The new test `res://tests/player/commando_animation_test.gd` verifies fallback actions and clip-name detection using a dummy AnimationPlayer. It **cannot** prove a future downloaded GLB is correctly rigged or visually convincing: do a real Windows on-screen playtest after adding the model.

## Design constraints

- The player `CharacterBody3D` physics collider, camera hierarchy and damage/ammo contracts are unchanged.
- Imported animations are selected based on movement/control state; firing/reload/death are action events.
- This is a basic clip-switching controller. True upper-body aiming overlays, blend-tree transitions, procedural IK and retargeting should be implemented after selecting a specific skeleton. Trying to author universal skeleton IK without a known rig produces unpredictable poses.
