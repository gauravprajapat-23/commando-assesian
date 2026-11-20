# AI-001 guard contract / integration

Scene: `res://scenes/enemies/guard.tscn` (root `CharacterBody3D`). Script: `res://scripts/enemies/guard.gd`.

Inject a player `Node3D` with `set_target(player)`, or add players to the configurable `target_group` (default `player`). Player should implement `take_damage(float)`, optionally `get_team() -> "player"`. Guard exposes `take_damage(amount: float)`, `get_team() -> "enemy"`, `alerted(target: Node3D)` and `died`; also emits `health_changed` and `attack_performed`.

Set `patrol_points` to `NodePath` values relative to the guard (e.g. child Marker3D nodes or reachable relative nodes). If empty, idle until a target is in sight. Guard's forward direction is local -Z. Enemy root collision layer is 2, mask 1; ensure player geometry/obstacles occupy layers included in the guard mask for LOS and physics queries. To detect player bodies on a different layer, include that layer in the guard's collision mask.

Navigation: `use_navigation=false` by default, so direct steering + `move_and_slide()` works without a navmesh (obstacles may cause sticking, not pathfinding). Enable `use_navigation=true` only after Master/World has baked a traversable NavigationRegion3D and verified NavigationAgent3D pathfinding; guard contains the agent already. Master should place guards at World `EnemySpawns` child markers and configure patrol paths and target; no worker edits to shared scene.

Test commands for a Godot 4 installation at repo root:

```sh
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/enemies/guard_ai_test.gd
```

**Execution status:** Godot executable unavailable in this agent environment; commands above are supplied for Master or CI to execute. No passing result is claimed.
