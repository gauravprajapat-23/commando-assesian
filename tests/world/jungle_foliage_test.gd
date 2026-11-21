extends SceneTree
## ISLAND-ART-02: Godot 4 headless integration contract for visual jungle dressing.
## godot --headless --path . --script res://tests/world/jungle_foliage_test.gd

const WORLD := preload("res://scenes/world/island_01.tscn")
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(condition: bool, label: String) -> void:
    if condition:
        print("PASS ISLAND-ART-02: " + label)
    else:
        failures += 1
        push_error("FAIL ISLAND-ART-02: " + label)

func _run() -> void:
    var island := WORLD.instantiate()
    root.add_child(island)
    await process_frame
    await physics_frame

    var foliage := island.get_node_or_null("JungleFoliage")
    _check(foliage != null and foliage is Node3D, "jungle dressing attached")
    if foliage == null:
        quit(1)
        return

    var expected := {
        "JungleTrunks": 34,
        "JungleCanopies": 34,
        "JungleShrubs": 72,
        "JungleStones": 28,
        "JungleGrass": 140
    }
    for name in expected.keys():
        var batch := foliage.get_node_or_null(name) as MultiMeshInstance3D
        _check(batch != null, name + " exists")
        if batch == null:
            continue
        _check(batch.multimesh != null, name + " has multimesh")
        if batch.multimesh == null:
            continue
        _check(batch.multimesh.instance_count == expected[name], name + " has expected instances")
        _check(batch.material_override != null, name + " has material")
        # In --headless, RenderingServer-backed get_instance_transform() may
        # return dummy positions. Validate CPU-side placement sent to MultiMesh.
        var positions: Array = batch.get_meta("placement_positions", [])
        _check(positions.size() == batch.multimesh.instance_count, name + " has matching CPU placement count")
        for i in range(positions.size()):
            var position: Vector3 = positions[i]
            _check(absf(position.x) >= 20.0, name + " keeps central corridor clear, index " + str(i))
            _check(position.z > -28.0 and position.z < 27.0, name + " stays clear of compound and landing, index " + str(i))

    var canopy := foliage.get_node_or_null("JungleCanopies") as MultiMeshInstance3D
    if canopy != null and canopy.multimesh != null:
        var canopy_mesh := canopy.multimesh.mesh as ArrayMesh
        _check(canopy_mesh != null, "tree crowns use custom radial leaf mesh")
        if canopy_mesh != null:
            _check(canopy_mesh.get_surface_count() == 1, "one shared canopy mesh surface")
            var vertices: PackedVector3Array = canopy_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            _check(vertices.size() >= 60, "leaf clusters contain multiple fronds")

    var first_palm := island.get_node_or_null("PalmCrown_00") as MeshInstance3D
    _check(first_palm != null and first_palm.mesh is ArrayMesh, "foreground palm uses leaf mesh rather than disk")
    # Extra dressing never replaces original static collision/cover.
    for child in foliage.get_children():
        _check(child is MultiMeshInstance3D, "visual-only MultiMesh nodes (no new collision)")
    _check(island.get_node_or_null("PlayerSpawn") is Marker3D, "player spawn unchanged")
    _check(island.get_node_or_null("ObjectivePoint") is Marker3D, "objective unchanged")
    _check(island.get_node_or_null("ExtractionPoint") is Marker3D, "extraction unchanged")
    _check(island.get_node_or_null("EnemySpawns/GuardA") is Marker3D, "enemy marker unchanged")
    quit(0 if failures == 0 else 1)
