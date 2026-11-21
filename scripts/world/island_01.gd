extends Node3D
## WORLD-001: standalone, low-poly island geometry. All units are Godot meters.
## Navigable ground top is y = 0. Marker feet are y = 0.5 for CharacterBody3D.
## No paths outside the World owner's directories are referenced.

const SAND := Color(0.80, 0.71, 0.47)
const GRASS := Color(0.24, 0.47, 0.24)
const JUNGLE := Color(0.12, 0.31, 0.16)
const LEAVES := Color(0.16, 0.42, 0.20)
const WOOD := Color(0.38, 0.25, 0.15)
const METAL := Color(0.34, 0.36, 0.31)
const ROCK := Color(0.39, 0.43, 0.40)
const WATER := Color(0.15, 0.50, 0.62)
const FLAG := Color(0.75, 0.20, 0.12)

const COASTAL_TERRAIN := preload("res://scripts/world/coastal_terrain.gd")

func _ready() -> void:
	_build_island()
	var coast := COASTAL_TERRAIN.new()
	coast.name = "CoastalTerrain"
	add_child(coast)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


func _box(name: String, at: Vector3, dimensions: Vector3, color: Color, solid: bool = true) -> Node3D:
	var holder := Node3D.new()
	holder.name = name
	holder.position = at
	add_child(holder)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	visual.material_override = _material(color)
	holder.add_child(visual)
	if solid:
		var body := StaticBody3D.new()
		body.name = "Collision"
		holder.add_child(body)
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = dimensions
		shape.shape = box_shape
		body.add_child(shape)
	return holder


func _cylinder(name: String, at: Vector3, radius: float, height: float, color: Color, solid: bool = true) -> Node3D:
	var holder := Node3D.new()
	holder.name = name
	holder.position = at
	add_child(holder)
	var visual := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	visual.mesh = mesh
	visual.material_override = _material(color)
	holder.add_child(visual)
	if solid:
		var body := StaticBody3D.new()
		body.name = "Collision"
		holder.add_child(body)
		var shape := CollisionShape3D.new()
		var cyl_shape := CylinderShape3D.new()
		cyl_shape.radius = radius
		cyl_shape.height = height
		shape.shape = cyl_shape
		body.add_child(shape)
	return holder


func _tree(index: int, at: Vector3, tall: float) -> void:
	_cylinder("PalmTrunk_%02d" % index, at + Vector3(0, tall * 0.5, 0), 0.40, tall, WOOD)
	var canopy := _cylinder("PalmCrown_%02d" % index, at + Vector3(0, tall + 0.6, 0), 2.3, 1.2, LEAVES, false)
	canopy.rotation_degrees.z = 8.0 * float(index % 3 - 1)


func _build_island() -> void:
	# Broad flat collision slabs form a continuous beach-to-outpost walking route.
	# Beach: z=18..50. Inland: z=-58..20. Both surfaces finish at y=0.
	_box("BeachLandingGround", Vector3(0, -1.0, 34), Vector3(94, 2, 32), SAND)
	_box("JungleGround", Vector3(0, -1.5, -19), Vector3(94, 3, 78), GRASS)
	# Water is a visual plane only: no surprise collision around the landing.
	_box("ShallowWaterVisual", Vector3(0, -1.7, 64), Vector3(130, 0.15, 32), WATER, false)
	# Forest on opposite sides creates cover while leaving x=-6..6 open.
	for i in range(12):
		var z_pos := -48.0 + float(i % 6) * 12.0
		var x_pos := -35.0 if i < 6 else 34.0
		_tree(i, Vector3(x_pos + float(i % 3) * 2.0, 0, z_pos), 5.5 + float(i % 3))
	# Additional collision cover near infiltration approach, away from center route.
	for i in range(8):
		var side := -1.0 if i % 2 == 0 else 1.0
		_box("JungleCover_%02d" % i, Vector3(side * (11.0 + float(i % 3) * 4.0), 1.0, 8.0 - float(i / 2) * 12.0), Vector3(3, 2, 2.5), ROCK)
	# Enemy outpost: barricades, two elevated watch stations and supply crates.
	_box("OutpostNorthWall", Vector3(0, 1.5, -54), Vector3(29, 3, 1.2), WOOD)
	_box("OutpostWestWall", Vector3(-15, 1.5, -42), Vector3(1.2, 3, 24), WOOD)
	_box("OutpostEastWall", Vector3(15, 1.5, -42), Vector3(1.2, 3, 24), WOOD)
	# South entry intentionally stays open from z=-30 to the objective.
	for side in [-1.0, 1.0]:
		_box("GateBarricade_%s" % str(side), Vector3(side * 11, 1.0, -30), Vector3(8, 2, 1.5), WOOD)
		_box("WatchPlatform_%s" % str(side), Vector3(side * 12, 4.0, -48), Vector3(5, 0.7, 5), METAL)
		for offset in [-1.8, 1.8]:
			_box("WatchSupport_%s_%s" % [str(side), str(offset)], Vector3(side * 12 + offset, 2, -48), Vector3(0.45, 4, 0.45), WOOD)
	for i in range(4):
		_box("OutpostCrate_%02d" % i, Vector3(-7 + float(i % 2) * 14, 0.9, -36 - float(i / 2) * 10), Vector3(2.5, 1.8, 2.5), WOOD)
	# Distinct objective landmark and extraction identifier, no trigger logic.
	_cylinder("ObjectiveMast", Vector3(0, 2.5, -44), 0.23, 5.0, METAL)
	_box("ObjectiveFlag", Vector3(1.1, 4.25, -44), Vector3(2.2, 1.0, 0.12), FLAG, false)
	_cylinder("ExtractionBeacon", Vector3(-24, 1.15, 35), 1.1, 2.3, METAL)
	_box("ExtractionLamp", Vector3(-24, 2.6, 35), Vector3(1.5, 0.6, 1.5), FLAG, false)
