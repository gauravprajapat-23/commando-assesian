# PLAYER-001 integration and verification

## Scene and public API
- Instantiate `res://scenes/player/commando.tscn` (root `CharacterBody3D`) at the world's `PlayerSpawn.global_transform`. No autoload or global scene reference.
- Script: `res://scripts/player/commando_controller.gd`; class `CommandoController`.
- `take_damage(amount: float) -> void` clamps health and emits `health_changed(current, maximum)`; on first lethal hit emits `died` once.
- `get_team() -> String` returns `"player"`.
- `ammo_changed(current: int, reserve: int)` is emitted on ready, fire, and reload. Connect UI to player signals.
- Hitscan uses `camera` forward ray in 3D world, `hit_mask` exported for physics collision setup; excludes player's own body RID. Damage receivers must expose `take_damage(amount)`; if they expose `get_team()`, player-team targets are protected.
- Default scene player collision layer 2 and world collision mask 1; target guards should be on physics layer 1 (or integrate by changing `hit_mask` on player instance).

## Controls (no InputMap configuration required)
- WASD moves relative to camera yaw; Space jumps; Shift sprints; Ctrl crouches; right mouse aims/orbits via mouse drag; left mouse shoots; R reloads.
- On mobile or in tests, call `set_control_state({"move": Vector2, "jump": bool, "sprint": bool, "crouch": bool, "aim": bool, "fire": bool, "reload": bool})` once per desired state change and `inject_look(yaw_delta_radians, pitch_delta_radians)` for camera motion. Missing state keys are false/zero. Call `clear_control_override()` to restore native keyboard/mouse polling.
- First-person look and mobile UI are out of scope. Master owns input hookup in shared files.
- Crouch capsule resizes with standing clearance ray; visual remains placeholder capsule (replace in player-owned assets in later milestones).

## Local Godot validation required
From repository root with Godot 4.x installed:
```bash
godot --headless --editor --path . --import --quit
godot --headless --path . --quit-after 2
godot --headless --path . --script res://tests/player/test_commando.gd
```
Execution evidence in this environment: **NOT RUN**. `command -v godot || command -v godot4` returned empty, and git remote network access was blocked (`Could not resolve host: github.com`). This is not a PASS claim; Master should run all three commands, resolve failures, and review before merging.

## Ownership
Changes limited to `scenes/player/**`, `scripts/player/**`, and `tests/player/**`. No shared scenes, `project.godot`, or other worker paths were modified.
