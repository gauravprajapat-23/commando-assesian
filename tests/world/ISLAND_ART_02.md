# ISLAND-ART-02 — Jungle foliage prototype

## Scope and design choice
This milestone adds deterministic low-poly jungle dressing using native Godot
`MultiMeshInstance3D`. The source trees, bushes, stones and grass are original
procedural meshes; no external packs, licensing dependencies, GDExtensions, or
renderer settings are introduced. This is a performance-oriented **art prototype**,
not photorealistic foliage.

- 34 new tree trunks with 34 canopies
- 72 shrubs
- 28 small decorative stones
- 140 grass patches
- **5** draw-batch nodes (MultiMeshInstance3D), not one scene node per plant
- Fixed deterministic positions; identical distribution between loads
- Decorative elements carry **no collision** to keep guard LOS and mission
  pathing stable; the original physical palms and rock cover remain
- Keep central corridor `abs(x) < 20` clear and stay out of the outpost
  (`z <= -28`) and landing/extraction area (`z >= 27`)

## Ownership
Only `scripts/world/**` and `tests/world/**` changed.
`scenes/world/island_01.tscn`, `scripts/core/main.gd`, `project.godot`,
player, guard, mission and HUD code remain untouched.

## Dependency
Independent of draft ISLAND-ART-01 PR #18, based directly on `dev`.
Both PRs add a node in `scripts/world/island_01.gd::_ready()`; integrate them
by retaining **both** `CoastalTerrain` and `JungleFoliage` initializations
during sequential merge. Do not silently overwrite either call.

## Verification (run with installed Godot 4, GL Compatibility)
```powershell
godot --headless --editor --path . --import
godot --headless --path . --quit-after 3
godot --headless --path . --script res://tests/world/island_01_contract.gd
godot --headless --path . --script res://tests/world/jungle_foliage_test.gd
godot --headless --fixed-fps 60 --path . --script res://tests/integration/island_01_flow.gd
```

Run the guard and player focused tests, and manually inspect the right and
left jungle edges in a rendered desktop session. The foliage batches intentionally
have no occluding collision; future stealth gameplay must introduce selective
collision-bearing cover on a separate acceptance gate. Check GL Compatibility and
Android device GPU memory/fill-rate before merging; MultiMesh reduces draw calls
but does not guarantee overall performance.

## Future art direction
Replace source meshes with appropriately licensed low-poly or stylized palms,
ferns, rocks, and shrubs while retaining batching, reproducible placements
and clear sightlines. Possible authoring addon: ProtonScatter, once the exact
Godot 4 version, license and exported runtime behavior are verified.
