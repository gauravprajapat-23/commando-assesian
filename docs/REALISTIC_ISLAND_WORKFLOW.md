# Island 01 — realistic asset and camera workflow

This project is still **procedural low-poly by default**. A photorealistic look requires licensed model assets, texture maps, suitable lighting and careful performance testing. The optional hooks below do **not** bundle assets or addons. All originals remain active when assets are missing.

## Godot editor viewport controls (built-in, not controlled by game scripts)

- Open `scenes/world/island_01_preview.tscn`, select `Island01`, press `F` to frame.
- Hold **middle mouse button** and drag to orbit; **Shift + middle mouse** to pan; mouse wheel to zoom.
- Hold **right mouse button + WASD** to fly through the editor viewport. Left-button drag selects, it does not orbit.
- If the middle button is missing: **Editor > Editor Settings > Editors > 3D > Emulate 3 Button Mouse**; choose the appropriate 3D navigation scheme.
- Select **Perspective** (not Top) for orbiting. The editor's orbit controls are separate from gameplay camera controls.

## In-game inspection camera (new)

Run the main scene (F5), press **F8** to toggle an independent spectator camera. While enabled:
- **Hold right mouse** and move to look around (release RMB to free the cursor).
- **Arrow keys** fly; **Q / E** move down / up; mouse wheel adjusts flight speed.
- Press **F8** again to return to player view.

This is a developer inspection tool, not a replacement for the player's camera.

## Optional realistic GLB replacements

Godot imports `.glb` through its built-in glTF importer. **You do not need Blender, Terrain3D or ProtonScatter** merely to import GLB files.

Create `res://assets/realism/` and add these externally sourced files:

| Optional file | Used for | Requirement |
| --- | --- | --- |
| `palm.glb` | Existing 12 gameplay palm tree visuals | Scene pivot at ground level, tree ~6 m tall; procedural trunk collision preserved |
| `tent.glb` | Two military canvas tent visuals | Entire tent model, centered at the tent's existing body origin |
| `barracks.glb` | Barracks exterior visuals | Centered at the current building body origin |

Optional tileable PBR textures (PNG, matching the listed names):

| Optional file | Applied to |
| --- | --- |
| `sand_albedo.png`, `sand_normal.png` | Beach landing ground |
| `ground_albedo.png`, `ground_normal.png` | Jungle ground |

These automatically replace flat ground color using triplanar UVs when present. Use matching CC0 albedo and tangent-space normal maps; check normal-map orientation and import settings in Godot. Textures are not included in the repository.

The optional models are *visual only*. Importing GLB files with collision nodes might introduce additional physics; use visual-only GLBs until a collision and line-of-sight pass is performed.

**Important:** these paths are placeholders until YOU place actual licensed GLB files there. No photoreal asset is shipped by this branch. Because each model's pivot, dimensions, orientation and material UVs differ, inspect and adjust their import transforms inside Godot. The default world has fallback geometry, not an asset download dependency.

## Trusted asset sources and recommended workflow

- [Poly Haven](https://polyhaven.com/models): photogrammetry / PBR models, CC0. Choose appropriate vegetation / environment GLB or convert supplied formats using Blender as needed.
- [ambientCG](https://ambientcg.com/): CC0 PBR terrain, sand, rock, concrete and foliage textures; export/import appropriately.
- [Quaternius](https://quaternius.com/): free game-ready models; often stylized rather than photoreal. Check the selected pack license.
- [Kenney](https://kenney.nl/assets): useful modular props and game assets, generally stylized; inspect pack licence.

Start with a single high-quality palm, a textured fabric tent and a textured barracks model, then optimize LODs, draw calls and texture sizes before scaling up.

For a major graphical quality increase, evaluate **Forward+** on capable desktop GPUs. Existing project targets **GL Compatibility** (including lower-end Intel UHD graphics); do not switch globally without FPS/device testing. Terrain3D requires a compatible GDExtension binary and renderer: it previously produced import errors here, so it is intentionally **not auto-installed**. ProtonScatter is also intentionally left disabled.

## Regenerate preview after code or asset changes

Close the open preview tab in Godot before regeneration, and then run:

```powershell
cd "C:\Users\gauravp\Projects\commando-assesian"
git pull --ff-only
& "C:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --editor --path . --import
& "C:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/world/generate_island_preview.gd
```

Reopen `scenes/world/island_01_preview.tscn`. It is an untracked/ignored generated snapshot, not the gameplay source.

### Release gates

Run `tests/world/verify_island_art.ps1` and perform visual/manual mouse navigation checks on Windows. Headless tests do not establish photorealism, normal-map rendering, correct GLB material imports or sustained GPU FPS.
