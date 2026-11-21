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
