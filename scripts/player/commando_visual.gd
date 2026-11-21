extends Node3D
## Native Godot tactical character, no external assets or editor addons needed.
## Forward is -Z; feet at y=0. Existing CharacterBody3D physics remains separate.
## Optional art upgrade: res://assets/characters/commando.glb
## Model should face -Z, have feet at origin, and measure approx. 1.8 meters tall.

const OLIVE := Color(0.24, 0.29, 0.19)
const DARK_OLIVE := Color(0.14, 0.19, 0.13)
const CLOTH := Color(0.35, 0.36, 0.29)
const KEVLAR := Color(0.16, 0.18, 0.15)
const BOOT := Color(0.11, 0.10, 0.09)
const SKIN := Color(0.55, 0.39, 0.29)
const METAL := Color(0.13, 0.15, 0.15)
const GLASS := Color(0.08, 0.16, 0.17)
const GEAR := Color(0.29, 0.30, 0.23)

var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var body_root: Node3D
var imported_model: Node3D
var time_walk := 0.0
var last_move_strength := 0.0
var default_materials: Dictionary = {}

func _ready() -> void:
    var model_path := "res://assets/characters/commando.glb"
    if ResourceLoader.exists(model_path):
        var scene := load(model_path) as PackedScene
        if scene != null:
            imported_model = scene.instantiate() as Node3D
            if imported_model != null:
                imported_model.name = "ImportedCommando"
                add_child(imported_model)
                return
    _create_character()

func _mat(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
    var key := str(color) + "|" + str(metallic)
    if default_materials.has(key):
        return default_materials[key]
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metallic
    mat.roughness = 0.9 if metallic == 0.0 else 0.57
    default_materials[key] = mat
    return mat

func _box(parent: Node3D, name: String, at: Vector3, size: Vector3, color: Color, metal: float = 0.0) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = name
    item.position = at
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.material_override = _mat(color, metal)
    parent.add_child(item)
    return item

func _sphere(parent: Node3D, name: String, at: Vector3, radius: float, color: Color, scale_factor: Vector3 = Vector3.ONE) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = name
    item.position = at
    item.scale = scale_factor
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    mesh.radial_segments = 12
    mesh.rings = 6
    item.mesh = mesh
    item.material_override = _mat(color)
    parent.add_child(item)
    return item

func _cylinder(parent: Node3D, name: String, at: Vector3, radius: float, length: float, color: Color) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = name
    item.position = at
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius * 0.8
    mesh.bottom_radius = radius
    mesh.height = length
    mesh.radial_segments = 9
    item.mesh = mesh
    item.material_override = _mat(color)
    parent.add_child(item)
    return item

func _pivot(name: String, at: Vector3) -> Node3D:
    var pivot := Node3D.new()
    pivot.name = name
    pivot.position = at
    add_child(pivot)
    return pivot

func _create_character() -> void:
    body_root = _pivot("TacticalUpperBody", Vector3.ZERO)
    _box(body_root, "TacticalJacket", Vector3(0.0, 1.20, 0.0), Vector3(0.58, 0.56, 0.31), OLIVE)
    _box(body_root, "ArmoredVest", Vector3(0, 1.24, -0.176), Vector3(0.54, 0.42, 0.11), KEVLAR)
    _box(body_root, "VestBack", Vector3(0, 1.25, 0.18), Vector3(0.49, 0.43, 0.09), KEVLAR)
    _box(body_root, "WaistBelt", Vector3(0, 0.91, 0), Vector3(0.59, 0.12, 0.34), GEAR)
    for i in range(3):
        _box(body_root, "AmmoPouch_%d" % i, Vector3(-0.19 + float(i) * 0.19, 1.14, -0.26), Vector3(0.15, 0.19, 0.10), GEAR)
    _box(body_root, "Radio", Vector3(0.25, 1.43, -0.20), Vector3(0.09, 0.19, 0.10), METAL)
    _box(body_root, "Backpack", Vector3(0, 1.22, 0.29), Vector3(0.45, 0.49, 0.27), DARK_OLIVE)
    _box(body_root, "PackRoll", Vector3(0, 1.50, 0.31), Vector3(0.45, 0.11, 0.22), CLOTH)
    for side in [-1.0, 1.0]:
        _box(body_root, "ShoulderStrap_%s" % str(side), Vector3(side * 0.20, 1.31, -0.222), Vector3(0.08, 0.36, 0.06), GEAR)
    _sphere(body_root, "Neck", Vector3(0, 1.56, 0), 0.11, SKIN, Vector3(0.8, 1.2, 0.8))
    _sphere(body_root, "Head", Vector3(0, 1.69, -0.005), 0.135, SKIN, Vector3(0.84, 1.06, 0.86))
    _sphere(body_root, "HelmetShell", Vector3(0, 1.79, 0), 0.16, DARK_OLIVE, Vector3(1.13, 0.83, 1.18))
    _box(body_root, "HelmetRim", Vector3(0, 1.725, -0.04), Vector3(0.34, 0.042, 0.31), KEVLAR)
    _box(body_root, "Goggles", Vector3(0, 1.697, -0.13), Vector3(0.24, 0.082, 0.057), GLASS)
    _box(body_root, "FaceMask", Vector3(0, 1.61, -0.126), Vector3(0.19, 0.073, 0.057), CLOTH)
    left_leg = _pivot("LeftLeg", Vector3(-0.17, 0.87, 0))
    right_leg = _pivot("RightLeg", Vector3(0.17, 0.87, 0))
    _make_leg(left_leg, "L")
    _make_leg(right_leg, "R")
    left_arm = _pivot("LeftArm", Vector3(-0.37, 1.43, 0))
    right_arm = _pivot("RightArm", Vector3(0.37, 1.43, 0))
    _make_arm(left_arm, "L")
    _make_arm(right_arm, "R")
    _make_rifle()

func _make_leg(pivot: Node3D, side: String) -> void:
    _sphere(pivot, side + "Hip", Vector3(0, -0.05, 0), 0.14, CLOTH)
    _cylinder(pivot, side + "Thigh", Vector3(0, -0.25, 0), 0.126, 0.42, CLOTH)
    _sphere(pivot, side + "KneePad", Vector3(0, -0.48, -0.065), 0.105, KEVLAR, Vector3(1.04, 0.85, 0.50))
    _cylinder(pivot, side + "Shin", Vector3(0, -0.63, 0.015), 0.101, 0.29, OLIVE)
    _box(pivot, side + "Boot", Vector3(0, -0.80, -0.075), Vector3(0.21, 0.18, 0.34), BOOT)

func _make_arm(pivot: Node3D, side: String) -> void:
    _sphere(pivot, side + "Shoulder", Vector3(0, 0.02, 0), 0.155, OLIVE)
    _cylinder(pivot, side + "Sleeve", Vector3(0, -0.18, -0.02), 0.11, 0.34, OLIVE)
    _sphere(pivot, side + "Elbow", Vector3(0, -0.37, -0.06), 0.09, KEVLAR)
    _cylinder(pivot, side + "Forearm", Vector3(0, -0.49, -0.14), 0.081, 0.23, CLOTH)
    _box(pivot, side + "Glove", Vector3(0, -0.63, -0.17), Vector3(0.17, 0.16, 0.14), BOOT)

func _make_rifle() -> void:
    # Weapon model is visual only: player hit-scan logic remains unchanged.
    var weapon := Node3D.new()
    weapon.name = "RifleVisual"
    weapon.position = Vector3(0.20, 1.19, -0.40)
    body_root.add_child(weapon)
    _box(weapon, "Receiver", Vector3(0, 0, -0.12), Vector3(0.12, 0.12, 0.44), METAL, 0.3)
    _box(weapon, "Handguard", Vector3(0, -0.01, -0.40), Vector3(0.095, 0.095, 0.32), KEVLAR)
    _cylinder(weapon, "Barrel", Vector3(0, -0.005, -0.69), 0.022, 0.29, METAL)
    var barrel := weapon.get_node("Barrel") as MeshInstance3D
    barrel.rotation.x = PI * 0.5
    _box(weapon, "Stock", Vector3(0, -0.045, 0.17), Vector3(0.105, 0.16, 0.28), BOOT)
    _box(weapon, "Magazine", Vector3(0, -0.16, -0.20), Vector3(0.082, 0.23, 0.13), METAL)
    _box(weapon, "Optic", Vector3(0, 0.11, -0.20), Vector3(0.075, 0.075, 0.16), GLASS)

func animate_character(delta: float, move_strength: float, sprinting: bool, aiming: bool, crouching: bool, dead: bool) -> void:
    if imported_model != null:
        # Imported animated rigs should be driven by their own AnimationTree.
        return
    if body_root == null:
        return
    if dead:
        body_root.rotation.z = lerpf(body_root.rotation.z, 1.25, delta * 3.0)
        return
    var intensity := clampf(move_strength, 0.0, 1.0)
    var speed := 12.0 if sprinting else 8.0
    time_walk += delta * speed * intensity
    var cycle := sin(time_walk) * intensity
    var arm_swing := cycle * (0.35 if aiming else 0.58)
    left_leg.rotation.x = lerpf(left_leg.rotation.x, cycle * 0.55, delta * 12.0)
    right_leg.rotation.x = lerpf(right_leg.rotation.x, -cycle * 0.55, delta * 12.0)
    left_arm.rotation.x = lerpf(left_arm.rotation.x, -0.48 - arm_swing, delta * 12.0)
    right_arm.rotation.x = lerpf(right_arm.rotation.x, -0.48 + arm_swing, delta * 12.0)
    body_root.position.y = lerpf(body_root.position.y, (-0.31 if crouching else 0.0) + absf(cycle) * 0.025, delta * 9.0)
    body_root.rotation.z = lerpf(body_root.rotation.z, 0.0, delta * 9.0)
