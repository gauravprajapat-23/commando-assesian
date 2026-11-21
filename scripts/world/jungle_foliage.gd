extends Node3D
## ISLAND-ART-02: deterministic, renderer-safe jungle dressing.
## Uses native MultiMeshInstance3D batches: no addon binaries or external assets.
## All foliage is decorative. Original trunks, cover, collision and mission route remain authoritative.

const TREE_COUNT := 34
const BUSH_COUNT := 72
const ROCK_COUNT := 28
const GRASS_COUNT := 140

func _ready() -> void:
    _build_foliage()

func _material(color: Color, double_sided: bool = false) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 1.0
    if double_sided:
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

func _scatter_position(index: int, count: int, salt: int) -> Vector3:
    # Stable side corridors. Nothing placed in x=-16..16 or the compound.
    var fraction := (float(index) + 0.5) / float(count)
    var side := -1.0 if index % 2 == 0 else 1.0
    var noise := sin(float(index * 29 + salt * 37) * 1.617)
    var outer := 23.0 + 18.0 * absf(sin(float(index * 13 + salt) * 0.61))
    var z := -23.0 + fraction * 45.0 + noise * 3.0
    return Vector3(side * outer, 0.0, clampf(z, -26.0, 24.0))

func _transform(at: Vector3, scale: Vector3, rotation: float = 0.0) -> Transform3D:
    return Transform3D(Basis(Vector3.UP, rotation).scaled(scale), at)

func _batch(name: String, source_mesh: Mesh, mat: Material, transforms: Array[Transform3D]) -> void:
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = source_mesh
    multimesh.instance_count = transforms.size()
    for i in range(transforms.size()):
        multimesh.set_instance_transform(i, transforms[i])
    var node := MultiMeshInstance3D.new()
    node.name = name
    node.multimesh = multimesh
    node.material_override = mat
    add_child(node)

func _build_foliage() -> void:
    var trunks: Array[Transform3D] = []
    var crowns: Array[Transform3D] = []
    var bushes: Array[Transform3D] = []
    var stones: Array[Transform3D] = []
    var grass: Array[Transform3D] = []

    for i in range(TREE_COUNT):
        var p := _scatter_position(i, TREE_COUNT, 1)
        var height := 4.4 + float(i % 5) * 0.43
        var twist := float(i % 9) * 0.38
        trunks.append(_transform(p + Vector3.UP * (height * 0.5), Vector3(0.25, height, 0.25), twist))
        crowns.append(_transform(p + Vector3.UP * (height + 0.5), Vector3(2.1, 1.15, 2.0), twist))
    for i in range(BUSH_COUNT):
        var p := _scatter_position(i, BUSH_COUNT, 2)
        var size := 0.6 + float(i % 5) * 0.13
        bushes.append(_transform(p + Vector3.UP * size, Vector3(size * 1.4, size, size * 1.25), float(i) * 0.72))
    for i in range(ROCK_COUNT):
        var p := _scatter_position(i, ROCK_COUNT, 3)
        var size := 0.6 + float(i % 4) * 0.23
        stones.append(_transform(p + Vector3.UP * (size * 0.35), Vector3(size * 1.5, size * 0.8, size), float(i) * 0.57))
    for i in range(GRASS_COUNT):
        var p := _scatter_position(i, GRASS_COUNT, 4)
        var size := 0.55 + float(i % 4) * 0.18
        grass.append(_transform(p + Vector3.UP * (size * 0.45), Vector3(size, size, size), float(i) * 1.13))

    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.65
    trunk_mesh.bottom_radius = 1.0
    trunk_mesh.height = 1.0
    trunk_mesh.radial_segments = 6
    _batch("JungleTrunks", trunk_mesh, _material(Color(0.34, 0.25, 0.17)), trunks)

    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 1.0
    crown_mesh.height = 2.0
    crown_mesh.radial_segments = 8
    crown_mesh.rings = 4
    _batch("JungleCanopies", crown_mesh, _material(Color(0.14, 0.35, 0.17)), crowns)
    _batch("JungleShrubs", crown_mesh, _material(Color(0.19, 0.43, 0.19)), bushes)

    var rock_mesh := SphereMesh.new()
    rock_mesh.radius = 1.0
    rock_mesh.height = 2.0
    rock_mesh.radial_segments = 7
    rock_mesh.rings = 3
    _batch("JungleStones", rock_mesh, _material(Color(0.38, 0.42, 0.39)), stones)

    var blade_mesh := QuadMesh.new()
    blade_mesh.size = Vector2(0.7, 0.85)
    _batch("JungleGrass", blade_mesh, _material(Color(0.30, 0.52, 0.20), true), grass)
