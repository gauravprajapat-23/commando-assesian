extends Node3D
## ISLAND-ART-01: lightweight, native Godot 4 coastal terrain prototype.
## This optional visual/collision skirt sits BELOW the existing gameplay ground,
## preserving all existing spawn markers, patrol routes and mission triggers.
## No GDExtension, editor plugin, imported binary, or renderer change required.

const STEP := 4.0
const X_MIN := -68.0
const X_MAX := 68.0
const Z_MIN := -76.0
const Z_MAX := 76.0
const BASE_HEIGHT := -0.20

func _ready() -> void:
    _create_coast()

func _height(x: float, z: float) -> float:
    # Existing walkable gameplay slabs: x=-47..47, z=-58..50.
    # A flat underlay avoids modifying traversal or marker heights.
    var lateral := maxf(absf(x) - 46.0, 0.0)
    var north := maxf(-58.0 - z, 0.0)
    var south := maxf(z - 50.0, 0.0)
    var edge := maxf(lateral, maxf(north, south))
    var shoreline := clampf(edge / 18.0, 0.0, 1.0)
    var smooth := shoreline * shoreline * (3.0 - 2.0 * shoreline)
    # Keep the underlay entirely below y=0, even at its highest point.
    var undulation := sin(x * 0.11) * cos(z * 0.13) * 0.45 * smooth
    return BASE_HEIGHT - 5.0 * smooth + undulation

func _create_coast() -> void:
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    var x_cells := int(round((X_MAX - X_MIN) / STEP))
    var z_cells := int(round((Z_MAX - Z_MIN) / STEP))
    for iz in range(z_cells):
        var z := Z_MIN + float(iz) * STEP
        for ix in range(x_cells):
            var x := X_MIN + float(ix) * STEP
            var a := Vector3(x, _height(x, z), z)
            var b := Vector3(x + STEP, _height(x + STEP, z), z)
            var c := Vector3(x, _height(x, z + STEP), z + STEP)
            var d := Vector3(x + STEP, _height(x + STEP, z + STEP), z + STEP)
            # Clockwise XZ ordering faces upward in Godot.
            _vertex(builder, a)
            _vertex(builder, c)
            _vertex(builder, b)
            _vertex(builder, b)
            _vertex(builder, c)
            _vertex(builder, d)
    builder.generate_normals()
    var mesh := builder.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 1.0
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    var terrain := MeshInstance3D.new()
    terrain.name = "CoastalMesh"
    terrain.mesh = mesh
    terrain.material_override = material
    add_child(terrain)

    var ground := StaticBody3D.new()
    ground.name = "CoastalCollision"
    ground.collision_layer = 1
    ground.collision_mask = 1
    var shape := CollisionShape3D.new()
    shape.name = "CollisionShape3D"
    shape.shape = mesh.create_trimesh_shape()
    ground.add_child(shape)
    add_child(ground)

func _vertex(builder: SurfaceTool, position: Vector3) -> void:
    # Vertex colors avoid external textures and stay GL Compatibility friendly.
    var sand := Color(0.78, 0.68, 0.43)
    var grass := Color(0.22, 0.43, 0.24)
    var mix_amount := clampf((16.0 - position.z) / 8.0, 0.0, 1.0)
    builder.set_color(sand.lerp(grass, mix_amount))
    builder.add_vertex(position)
