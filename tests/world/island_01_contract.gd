extends SceneTree
## Run from project root:
## godot --headless --path . --editor --import
## godot --headless --path . --script res://tests/world/island_01_contract.gd

const WORLD_PATH := "res://scenes/world/island_01.tscn"


func _initialize() -> void:
	call_deferred("_verify")


func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("FAIL WORLD-001: " + message)
		return false
	return true


func _verify() -> void:
	var packed := load(WORLD_PATH) as PackedScene
	if not _check(packed != null, "island scene must load"):
		quit(1)
		return
	var island := packed.instantiate()
	root.add_child(island)
	await process_frame
	await physics_frame
	var ok := true
	ok = _check(island is Node3D, "scene root must be Node3D") and ok
	for path in ["PlayerSpawn", "ObjectivePoint", "ExtractionPoint"]:
		ok = _check(island.get_node_or_null(path) is Marker3D, path + " must be Marker3D") and ok
	var spawn_group := island.get_node_or_null("EnemySpawns")
	ok = _check(spawn_group is Node3D, "EnemySpawns must be Node3D") and ok
	if spawn_group != null:
		ok = _check(spawn_group.get_child_count() >= 3, "at least three enemy spawn markers") and ok
		for marker in spawn_group.get_children():
			ok = _check(marker is Marker3D, "enemy spawn child must be Marker3D") and ok
	var player := island.get_node_or_null("PlayerSpawn") as Marker3D
	var objective := island.get_node_or_null("ObjectivePoint") as Marker3D
	var extraction := island.get_node_or_null("ExtractionPoint") as Marker3D
	if player != null and objective != null and extraction != null:
		ok = _check(player.global_position.z > 20.0, "landing spawn lies on beach") and ok
		ok = _check(objective.global_position.z < -30.0, "objective lies inside outpost") and ok
		ok = _check(extraction.global_position.distance_to(player.global_position) > 12.0, "extraction is separate from landing") and ok
	var solid_count := 0
	for child in island.get_children():
		for body in child.get_children():
			if body is StaticBody3D:
				solid_count += 1
				ok = _check(body.get_node_or_null("CollisionShape3D") != null or _has_collision_shape(body), "static body has collision shape") and ok
	ok = _check(solid_count >= 25, "terrain and cover require physical collisions") and ok
	if ok:
		print("PASS WORLD-001: root, four spawn contracts, beach/outpost/extraction layout, %d solid colliders" % solid_count)
		quit(0)
	else:
		quit(1)


func _has_collision_shape(body: Node) -> bool:
	for child in body.get_children():
		if child is CollisionShape3D and child.shape != null and not child.disabled:
			return true
	return false
