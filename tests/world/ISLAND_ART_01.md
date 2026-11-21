# ISLAND-ART-01 — Coastal Terrain Prototype

## Decision
Keep the repository's Godot 4 GL Compatibility renderer and existing gameplay slabs.
Use a **native Godot SurfaceTool/ArrayMesh underlay**, not an installed GDExtension.
The added coast slopes down outside the current walkable x=-47..47 / z=-58..50
footprint; it is intentionally below the original flat surface throughout.
This is a reversible terrain **prototype**, not a replacement terrain/navmesh.

## Terrain3D evaluation
- Terrain3D is a viable future terrain-authoring option on compatible Godot
  versions (Godot 4.4+ and Terrain3D 1.0+ support Compatibility).
- It requires a version-pinned GDExtension and per-platform binaries/export
  validation. This small Island 01 does not yet warrant that deployment cost.
- Don't vendor Terrain3D into this PR. Reconsider when we need sculpting,
  texture splats, larger islands or artist-controlled terrain.
- Future authoring: https://github.com/TokisanGames/Terrain3D
- Native fallback: https://docs.godotengine.org/en/4.6/tutorials/3d/procedural_geometry/surfacetool.html

## Preservation and ownership
- Modified files are exclusively `scripts/world/**` and `tests/world/**`.
- `scenes/world/island_01.tscn`, markers, spawn positions, 39 existing
  primitives/colliders, objective/extraction triggers and mission scripts
  are unchanged.
- New generated `CoastalTerrain/CoastalMesh` and
  `CoastalTerrain/CoastalCollision` nodes are added at runtime.
- Collision uses static concave trimesh; no physics or renderer project changes.
- Existing flat gameplay slabs remain authoritative in the walkable footprint.

## Verification commands (Godot 4.6.3+ recommended)
Run from the repository root on Windows with an installed Godot 4 binary:

```powershell
godot --headless --editor --path . --import
godot --headless --path . --quit-after 3
godot --headless --path . --script res://tests/world/island_01_contract.gd
godot --headless --path . --script res://tests/world/coastal_terrain_test.gd
godot --headless --fixed-fps 60 --path . --script res://tests/integration/island_01_flow.gd
```

Also run the existing player, enemy, mission, and HUD focused suites.
Manually inspect the southern beach, shoreline and open north/east/west
slopes in rendered GL Compatibility mode. Verify that player traverses from
beach to base and extracts, without collision pop, falling or invisible walls.

## Limitations
The underlay deliberately preserves blockout geometry. Water and foliage
remain unchanged, no Terrain3D addon is installed, and there is no navmesh
baking in this milestone. No claim of Android or rendered acceptance without
real device/renderer execution.
