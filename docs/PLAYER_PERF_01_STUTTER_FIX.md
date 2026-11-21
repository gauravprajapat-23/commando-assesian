# PLAYER-PERF-01 — Walk, Sprint and Animation Stutter Fix

## Observed source-level issues

The imported military GLB provides 50 clips, including Run, Walk, Aim, Crouch and Shoot. The player previously called `animate_character()` from `_physics_process()` but allowed the imported AnimationPlayer to use its scene-imported update mode. Locomotion blended over a fixed 0.18s, and full-body Shoot interrupted movement on each shot. For a rifle firing every 0.12s this can cause repeated transition stutter.

This change:
- Sets the imported AnimationPlayer's callback to **physics**, aligned with player input and motion calculations.
- Uses shorter configurable movement blending (`locomotion_blend_seconds`, default 0.10s).
- Adds editable walk/run playback-speed factors (defaults 1.0 and 1.35) to reduce foot sliding. Speed is interpolated without restarting the current clip.
- Prevents the full-body Shoot clip from interrupting Walk/Run every shot while moving. Stationary shooting still triggers it. Damage and ammo calculation are unchanged.
- Tracks animation switches and adds a regression test proving sustained sprint does not restart the clip unnecessarily.

## Test on Windows

```powershell
cd "C:\Users\gauravp\Projects\commando-assesian"
git fetch origin
git pull --ff-only
& "C:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --editor --path . --import
powershell -ExecutionPolicy Bypass -File .\tests\world\verify_island_art.ps1 -GodotExe "C:\Godot\Godot_v4.7.2-stable_win64.exe"
```

Manual quality gate: launch F5; hold W, W+Shift, W+RMB, crouch+W and W+left-click. Compare motion speed, foot sliding, transition jerks and frame-time spikes. Check F8 spectator camera still works.

For remaining *system-wide* performance drops on Intel UHD 630, open Godot **Debugger > Profiler** and **Monitors**, record FPS and frame time while running with/without player animation, note the expensive render or physics subsystem. Source inspection alone cannot establish a specific GPU/CPU bottleneck. This commit does not change the renderer or scene art quality.
