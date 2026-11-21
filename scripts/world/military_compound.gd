extends Node3D
## ISLAND-ART-03: GL Compatibility-safe modular military compound dressing.
## Visual-only architecture layered over WORLD-001's tested collision blockout.
## No additional collision; existing guard LOS and mission triggers remain authoritative.

const WALL := Color(0.30, 0.35, 0.29)
const TRIM := Color(0.19, 0.23, 0.21)
const CANVAS := Color(0.42, 0.44, 0.29)
const SAND := Color(0.59, 0.52, 0.35)
const STEEL := Color(0.45, 0.47, 0.43)
const LAMP := Color(1.0, 0.76, 0.39)

func _ready() -> void:
	_build()

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	return material

func _part(name: String, position: Vector3, size: Vector3, color: Color, angle: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _material(color)
	node.position = position
	node.rotation.y = angle
	add_child(node)
	return node

func _post(name: String, position: Vector3, height: float, radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := CylinderMesh.new()
	mesh.height = height
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.radial_segments = 8
	node.mesh = mesh
	node.material_override = _material(color)
	node.position = position
	add_child(node)
	return node

func _tower(side: int) -> void:
	var x := float(side) * 12.0
	var prefix := "West" if side < 0 else "East"
	# Existing platform top is 4.35; added parts begin above it.
	_part(prefix + "TowerRoof", Vector3(x, 7.0, -48), Vector3(5.6, 0.34, 5.6), CANVAS)
	for sx in [-2.1, 2.1]:
		for sz in [-2.1, 2.1]:
			_post(prefix + "TowerRail_%s_%s" % [str(sx), str(sz)], Vector3(x + sx, 5.55, -48 + sz), 2.7, 0.10, STEEL)
	for z in [-50.1, -45.9]:
		_part(prefix + "TowerGuardrail_" + str(z), Vector3(x, 4.75, z), Vector3(4.1, 0.18, 0.15), STEEL)
	# Small unlit searchlight housing for cheap GL Compatibility draw cost.
	_part(prefix + "SearchlightHousing", Vector3(x, 4.7, -48), Vector3(0.9, 0.45, 0.7), TRIM)
	_part(prefix + "SearchlightLens", Vector3(x, 4.7, -47.57), Vector3(0.6, 0.28, 0.08), LAMP)

func _tent(side: int) -> void:
	# Both tents are outside the outpost wall, well off the x=-6..6 route.
	var x := float(side) * 23.0
	var prefix := "West" if side < 0 else "East"
	_part(prefix + "TentDeck", Vector3(x, 0.12, -18), Vector3(7.6, 0.24, 6.4), SAND)
	_part(prefix + "TentBody", Vector3(x, 1.6, -18), Vector3(6.4, 2.8, 5.4), CANVAS)
	var roof_l := _part(prefix + "TentRoofL", Vector3(x - 1.62, 3.35, -18), Vector3(4.0, 0.20, 6.0), CANVAS)
	roof_l.rotation.z = -0.55
	var roof_r := _part(prefix + "TentRoofR", Vector3(x + 1.62, 3.35, -18), Vector3(4.0, 0.20, 6.0), CANVAS)
	roof_r.rotation.z = 0.55
	_part(prefix + "TentEntrance", Vector3(x, 1.5, -15.26), Vector3(1.6, 2.5, 0.10), TRIM)
	for dz in [-2.6, 2.6]:
		for dx in [-3.1, 3.1]:
			_post(prefix + "TentStake_%s_%s" % [str(dx), str(dz)], Vector3(x + dx, 0.43, -18 + dz), 0.86, 0.08, STEEL)

func _barracks() -> void:
	# Exterior barracks, beyond east wall (wall occupies x~15), no new walls in combat yard.
	_part("BarracksFoundation", Vector3(24.5, 0.22, -45), Vector3(10.0, 0.44, 12.0), SAND)
	_part("BarracksBuilding", Vector3(24.5, 2.45, -45), Vector3(9.0, 4.1, 11.0), WALL)
	_part("BarracksRoof", Vector3(24.5, 4.65, -45), Vector3(10.0, 0.36, 12.0), TRIM)
	_part("BarracksDoor", Vector3(19.94, 1.5, -45), Vector3(0.13, 2.7, 1.6), STEEL)
	for z in [-48.4, -41.6]:
		_part("BarracksWindow_" + str(z), Vector3(19.9, 2.65, z), Vector3(0.14, 1.0, 1.9), TRIM)

func _crate_straps() -> void:
	# Decorative bands overlay existing crate meshes/colliders at x=-7/7.
	for i in range(4):
		var x := -7.0 + float(i % 2) * 14.0
		var z := -36.0 - float(i / 2) * 10.0
		_part("CrateStrapA_%d" % i, Vector3(x, 1.82, z), Vector3(0.26, 0.06, 2.52), STEEL)
		_part("CrateStrapB_%d" % i, Vector3(x, 1.82, z), Vector3(2.52, 0.06, 0.26), STEEL)

func _perimeter_details() -> void:
	# High wall cap / wall panels, no footprints added outside existing blockout.
	_part("NorthWallCap", Vector3(0, 3.12, -54), Vector3(29.3, 0.24, 1.35), TRIM)
	for x in [-15.0, 15.0]:
		_part("SideWallCap_" + str(x), Vector3(x, 3.12, -42), Vector3(1.35, 0.24, 24.0), TRIM)
	for x in [-11.0, 11.0]:
		_part("GateMarking_" + str(x), Vector3(x, 2.07, -29.15), Vector3(2.7, 0.15, 0.08), SAND)
	# Lamps glow visually; no shadow-casting real-time lights in first pass.
	for x in [-12.0, 12.0]:
		_post("GateLampPole_" + str(x), Vector3(x, 3.45, -31), 2.7, 0.12, STEEL)
		_part("GateLamp_" + str(x), Vector3(x, 4.9, -31), Vector3(0.62, 0.24, 0.58), LAMP)

func _build() -> void:
	_tower(-1)
	_tower(1)
	_tent(-1)
	_tent(1)
	_barracks()
	_crate_straps()
	_perimeter_details()
