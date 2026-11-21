extends SceneTree
## ISLAND-ART-03: godot --headless --path . --script res://tests/world/military_compound_test.gd

const WORLD := preload("res://scenes/world/island_01.tscn")
var failures := 0

func _initialize() -> void:
    call_deferred("_verify")

func _check(value: bool, message: String) -> void:
    if value:
        print("PASS ISLAND-ART-03: " + message)
    else:
        failures += 1
        push_error("FAIL ISLAND-ART-03: " + message)

func _verify() -> void:
    var island := WORLD.instantiate()
    root.add_child(island)
    await process_frame
    await physics_frame
    var art := island.get_node_or_null("MilitaryCompound")
    _check(art is Node3D, "military compound is attached")
    if art == null:
        quit(1)
        return
    for label in [
        "WestTowerRoof", "EastTowerRoof",
        "WestTentBody", "EastTentBody",
        "BarracksBuilding", "BarracksDoor",
        "NorthWallCap",
        "CrateStrapA_0", "CrateStrapB_3"
    ]:
        _check(art.get_node_or_null(label) is MeshInstance3D, label + " decorative mesh exists")
    # Roof planes must climb toward the center ridge, not slope outward.
    for prefix in ["West", "East"]:
        var roof_left := art.get_node_or_null(prefix + "TentRoofL") as MeshInstance3D
        var roof_right := art.get_node_or_null(prefix + "TentRoofR") as MeshInstance3D
        _check(roof_left != null and roof_right != null, prefix + " tent has both roof planes")
        if roof_left != null and roof_right != null:
            _check(roof_left.rotation.z > 0.1 and roof_right.rotation.z < -0.1, prefix + " tent roof slopes toward centered ridge")
            _check(absf(roof_left.position.y - roof_right.position.y) < 0.01, prefix + " roof halves are aligned")
        _check(art.get_node_or_null(prefix + "TentRidgeCap") is MeshInstance3D, prefix + " tent ridge cap exists")
    var barracks_left := art.get_node_or_null("BarracksRoof") as MeshInstance3D
    var barracks_right := art.get_node_or_null("BarracksRoofRight") as MeshInstance3D
    _check(barracks_left != null and barracks_right != null, "barracks has two gable roof halves")
    if barracks_left != null and barracks_right != null:
        _check(barracks_left.rotation.z > 0.1 and barracks_right.rotation.z < -0.1, "barracks roof rises toward center")
    _check(art.get_node_or_null("BarracksRidgeCap") is MeshInstance3D, "barracks ridge cap exists")
    # Godot may normalize a node name containing a floating-point suffix.
    # Check the required meshes at their real design coordinates instead.
    for x in [-12.0, 12.0]:
        var lamp_found := false
        for part in art.get_children():
            if part is MeshInstance3D and part.name.begins_with("GateLamp_") and part.position.distance_to(Vector3(x, 4.9, -31.0)) < 0.01:
                lamp_found = true
                break
        _check(lamp_found, "gate lamp mesh exists at x=" + str(x))
    for part in art.get_children():
        _check(part is MeshInstance3D, "new compound art only contains visual meshes")
    for label in ["OutpostNorthWall", "OutpostWestWall", "OutpostEastWall"]:
        _check(island.get_node_or_null(label) != null, label + " existing physical blockout preserved")
    for side in [-1.0, 1.0]:
        var platform_found := false
        for part in island.get_children():
            if part is Node3D and part.name.begins_with("WatchPlatform_") and part.position.distance_to(Vector3(side * 12.0, 4.0, -48.0)) < 0.01:
                platform_found = part.get_node_or_null("Collision") is StaticBody3D
                break
        _check(platform_found, "physical watch platform preserved at side=" + str(side))
    for label in ["PlayerSpawn", "ObjectivePoint", "ExtractionPoint", "EnemySpawns/GuardA", "EnemySpawns/GuardB", "EnemySpawns/GuardC"]:
        _check(island.get_node_or_null(label) is Marker3D, label + " marker preserved")
    _check(island.get_node("PlayerSpawn").position == Vector3(0, 0.5, 37), "landing position unchanged")
    _check(island.get_node("ObjectivePoint").position == Vector3(0, 0.5, -44), "objective position unchanged")
    _check(island.get_node("ExtractionPoint").position == Vector3(-24, 0.5, 35), "extraction position unchanged")
    quit(0 if failures == 0 else 1)
