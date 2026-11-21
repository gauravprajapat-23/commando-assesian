extends SceneTree
## ISLAND-ART-04 — godot --headless --path . --script res://tests/world/ocean_atmosphere_test.gd

const WORLD := preload("res://scenes/world/island_01.tscn")
var failures := 0

func _initialize() -> void:
    call_deferred("_verify")

func _check(condition: bool, message: String) -> void:
    if condition:
        print("PASS ISLAND-ART-04: " + message)
    else:
        failures += 1
        push_error("FAIL ISLAND-ART-04: " + message)

func _verify() -> void:
    var island := WORLD.instantiate()
    root.add_child(island)
    await process_frame
    await physics_frame

    var art := island.get_node_or_null("OceanAtmosphere")
    _check(art is Node3D, "ocean and atmosphere node attached")
    if art == null:
        quit(1)
        return

    var ocean := art.get_node_or_null("OceanSurface") as MeshInstance3D
    _check(ocean != null and ocean.mesh is PlaneMesh, "ocean uses lightweight plane mesh")
    if ocean != null:
        _check(ocean.material_override is ShaderMaterial, "ocean uses a shader")
        _check(ocean.position.y < -1.6, "ocean lies below walkable beach")
        if ocean.material_override is ShaderMaterial:
            var material := ocean.material_override as ShaderMaterial
            _check(material.shader != null and material.shader.code.contains("TIME"), "water animates without compute shader")
            _check(not material.shader.code.contains("screen_texture"), "no screen texture dependency")
    for i in range(3):
        var foam := art.get_node_or_null("ShoreFoam_%d" % i)
        _check(foam is MeshInstance3D, "shoreline band %d exists" % i)
    var env := art.get_node_or_null("IslandEnvironment") as WorldEnvironment
    _check(env != null and env.environment != null, "island environment exists")
    var sun := art.get_node_or_null("IslandSun") as DirectionalLight3D
    _check(sun != null and not sun.shadow_enabled, "sun uses shadow-free lighting")

    for child in art.get_children():
        _check(not (child is CollisionObject3D), "new environment does not introduce collision")
    _check(island.get_node_or_null("PlayerSpawn") is Marker3D, "player spawn preserved")
    _check(island.get_node_or_null("ObjectivePoint") is Marker3D, "objective marker preserved")
    _check(island.get_node_or_null("ExtractionPoint") is Marker3D, "extraction marker preserved")
    quit(0 if failures == 0 else 1)
