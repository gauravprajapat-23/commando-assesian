# ISLAND-ART-03 — Military compound art prototype

## Scope
Upgrade the WORLD-001 outpost visually without changing combat, collisions,
spawns, objective markers, extraction or the GL Compatibility renderer.

New original Godot built-in procedural meshes:
- 2 covered guard towers with rails and searchlight housings
- 2 canvas field tents, positioned west/east of the approach
- 1 exterior barracks building with roof, windows and door
- 4 existing crate strap sets
- Perimeter wall caps, gate markings and decorative lamp housings

All new nodes are `MeshInstance3D` children of the single `MilitaryCompound`
node. They use original generated geometry only (no downloadable licensed assets
or external addon), avoid real-time shadow-casting lights and keep the existing
`project.godot` GL Compatibility renderer.

## Safety boundaries
- No changed scene marker coordinates; existing WORLD-001 ground and 39
  colliders stay authoritative.
- No changes to `scripts/core/main.gd`, guard AI, player, mission controller,
  HUD, scenes or `project.godot`.
- Main infiltration path x=-6..6 remains clear of the new external buildings.
- Existing guard combat collision and raycast LOS are unchanged.
- **Limitation:** New barracks/tents are visual-only until collision and
  navigation are deliberately reviewed. Players might pass through these
  exterior props if they can reach them. Do not accept release quality until
  appropriate static collision and pathfinding are added and tested.
- This is modular blockout-level military art, not imported photorealistic meshes.

## PR dependency
This branch is based directly on `dev` and independent of still-draft
PR #18 (coastal terrain) and PR #19 (jungle foliage). All three modify
`scripts/world/island_01.gd` around `_ready()`. During integration,
preserve each of the `CoastalTerrain`, `JungleFoliage`, and
`MilitaryCompound` initialization calls; do not blindly replace one with
another. Review visual overlap between foliage and external tents/barracks.

## Verification — Godot 4.6.3 or newer
```powershell
godot --headless --editor --path . --import
godot --headless --path . --quit-after 3
godot --headless --path . --script res://tests/world/island_01_contract.gd
godot --headless --path . --script res://tests/world/military_compound_test.gd
godot --headless --fixed-fps 60 --path . --script res://tests/integration/island_01_flow.gd
```

Additionally run focused guard/player/mission/UI tests, rendered GL
Compatibility keyboard/mouse acceptance, and check Android draw calls,
visibility and stability before moving from draft.

## Next gates
1. Headless import/GDScript parse and all regression suites.
2. Rendered review for obvious z-fighting or occlusion at the watchtowers,
   gate, crate edges and barracks.
3. Physically collidable barracks and tents, with nav/LOS and patrol validation.
4. Licensed model replacement, baked lighting and LOD if needed.
