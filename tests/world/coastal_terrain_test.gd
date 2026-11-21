extends SceneTree
## ISLAND-ART-01: godot --headless --path . --script res://tests/world/coastal_terrain_test.gd

const WORLD := preload("res://scenes/world/island_01.tscn")
var failures := 0

func _initialize() -> void:
    call_deferred("_verify")

func _check(condition: bool, label: String) -> void:
    if condition:
        print("PASS ISLAND-ART-01: " + label)
    else:
        failures += 1
        push_error("FAIL ISLAND-ART-01: " + label)

func _verify() -> void:
    var island := WORLD.instantiate()
    root.add_child(island)
    await process_frame
    await physics_frame

    var coast := island.get_node_or_null("CoastalTerrain")
    _check(coast != null and coast is Node3D, "coastal terrain added to Island 01")
    if coast == null:
        quit(1)
        return
    var terrain := coast.get_node_or_null("CoastalMesh") as MeshInstance3D
    var body := coast.get_node_or_null("CoastalCollision") as StaticBody3D
    _check(terrain != null and terrain.mesh != null, "generated ArrayMesh exists")
    _check(body != null and body.get_node_or_null("CollisionShape3D") != null, "terrain collision exists")
    if terrain != null and terrain.mesh != null:
        _check(terrain.mesh.get_surface_count() == 1, "single static terrain surface")
    if body != null:
        var collider := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
        _check(collider != null and collider.shape is ConcavePolygonShape3D, "terrain uses triangle mesh collision")

    for marker_path in ["PlayerSpawn", "ObjectivePoint", "ExtractionPoint", "EnemySpawns/GuardA", "EnemySpawns/GuardB", "EnemySpawns/GuardC"]:
        var marker := island.get_node_or_null(marker_path) as Marker3D
        _check(marker != null and absf(marker.position.y - 0.5) < 0.001, marker_path + " remains at expected gameplay height")

    # The new underlay must never rise above the original y=0 collision slabs.
    for x in [-68.0, -46.0, 0.0, 46.0, 68.0]:
        for z in [-76.0, -58.0, 0.0, 50.0, 76.0]:
            _check(coast._height(x, z) < 0.0, "underlay below original ground at (%s, %s)" % [str(x), str(z)])
    _check(absf(coast._height(0.0, 0.0) + 0.2) < 0.001, "central gameplay route remains flat")
    _check(coast._height(68.0, 76.0) < -3.0, "outer coast slopes below island")
    quit(0 if failures == 0 else 1)
