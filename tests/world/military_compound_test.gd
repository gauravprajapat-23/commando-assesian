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
        "NorthWallCap", "GateLamp_-12.0", "GateLamp_12.0",
        "CrateStrapA_0", "CrateStrapB_3"
    ]:
        _check(art.get_node_or_null(label) is MeshInstance3D, label + " decorative mesh exists")
    for part in art.get_children():
        _check(part is MeshInstance3D, "new compound art only contains visual meshes")
    for label in ["OutpostNorthWall", "OutpostWestWall", "OutpostEastWall", "WatchPlatform_-1.0", "WatchPlatform_1.0"]:
        _check(island.get_node_or_null(label) != null, label + " existing physical blockout preserved")
    for label in ["PlayerSpawn", "ObjectivePoint", "ExtractionPoint", "EnemySpawns/GuardA", "EnemySpawns/GuardB", "EnemySpawns/GuardC"]:
        _check(island.get_node_or_null(label) is Marker3D, label + " marker preserved")
    _check(island.get_node("PlayerSpawn").position == Vector3(0, 0.5, 37), "landing position unchanged")
    _check(island.get_node("ObjectivePoint").position == Vector3(0, 0.5, -44), "objective position unchanged")
    _check(island.get_node("ExtractionPoint").position == Vector3(-24, 0.5, 35), "extraction position unchanged")
    quit(0 if failures == 0 else 1)
