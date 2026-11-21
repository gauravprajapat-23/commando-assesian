# PLAYER-ANIM-03B — Military soldier and combat-animation retargeting

## Current completion boundary

The branch supplies an **optional rigged military soldier installer**, a same-skeleton action-library loading hook, and a skeleton-track validation gate. It does **not** bundle an already retargeted set of rifle animation clips or prove final cinematic character quality. The fallback procedural character still works without downloads.

## Install the military soldier (CC BY 4.0)

The installer retrieves `soldier.glb` from [cktang88/3d-fps](https://github.com/cktang88/3d-fps), where the rig and animations are credited to ["FREE [Military Soldier] RIGGED" by BAMEN](https://sketchfab.com/3d-models/free-military-soldier-rigged-e9c56308a67d4a3db62e914fafa4d198) under Creative Commons Attribution 4.0. This source is not guaranteed to be photorealistic; inspect texture quality, triangle count and clip coverage in Godot.

```powershell
cd "C:\Users\gauravp\Projects\commando-assesian"
git switch fix/godot-windows-runner-addon-isolation
git fetch origin
git pull --ff-only

# Installs ONLY when no existing commando.glb is present:
powershell -ExecutionPolicy Bypass -File .\tools\install_military_soldier.ps1

# If a previous starter was installed, deliberately back it up first:
# powershell -ExecutionPolicy Bypass -File .\tools\install_military_soldier.ps1 -ReplaceExisting

& "C:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --editor --path . --import
& "C:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/player/commando_asset_test.gd
```

The installer validates GLB v2 header, embedded skin(s), mesh(es), and animations before installing. It generates `assets/characters/MILITARY_SOLDIER_ATTRIBUTION.txt`. Keep that credit with your game. No assets are automatically added to Git history, and downloading or using assets requires checking the original terms and any adaptations.

## Import and retarget action clips with Godot 4.7

Godot officially supports **BoneMap**, **SkeletonProfileHumanoid**, and humanoid animation retargeting in its Advanced Import Settings: [Godot 4.7 — Retargeting 3D Skeletons](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html).

1. In FileSystem, select `commando.glb` and open **Advanced Import Settings**. Inspect its `Skeleton3D` and choose an appropriate `BoneMap` with the `SkeletonProfileHumanoid` profile.
2. Map hips, spine, head, arms, hands, legs and feet to the corresponding bones in the imported soldier. Ensure its original rest pose and bone orientation are consistent.
3. Import your licensed source action animations (crouch, rifle ADS, rifle fire, reload, death) **as AnimationLibrary**, with an appropriate humanoid BoneMap. Map source and target bones to the same humanoid profile, then reimport.
4. Normalize transforms and remove unwanted root-motion translation on the imported actions; the player CharacterBody3D already owns movement. Ensure clips use the soldier's target bone paths (simply renaming clips cannot retarget them).
5. Save/export the successfully retargeted action library at `res://assets/characters/commando_actions.tres`. The visual adapter loads this optional library as `combat` on the soldier's AnimationPlayer and discovers clips by names such as `combat/Reload` or `combat/Death`. No external addon is required.
6. Verify foot contacts, weapon grip/hand orientation, muzzle alignment, crouched collider height, and that death is not replayed every frame. Test rear/side/front views using F8 overview.

**Clip naming:** Idle/Walk/Run should exist on the character's rig; optional Crouch, Aim, Fire, Reload and Death can come from the retargeted AnimationLibrary. Imported clips are selected by names/aliases; absent clips fall back to available movement animations. The adapter does *not* implement per-bone upper-body layers or inverse kinematics. Those will need separate model-specific work.

## Validate after import

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\world\verify_island_art.ps1 -GodotExe "C:\Godot\Godot_v4.7.2-stable_win64.exe"
```

The test `res://tests/player/commando_asset_test.gd` checks imported skeleton bones, Idle/Walk/Run mapping and at least one skeletal-animation transform track. Its presence does not replace manual animation/texture review. Record a gameplay video before release to verify the model is not reversed, floating, clipping or missing PBR textures.

**Hardware:** The target test PC uses Intel UHD Graphics 630 and GL Compatibility; avoid Forward+-only shaders and oversized 4K materials before FPS profiling.
