extends SceneTree
## One-time editor preview baker. Run with:
## Godot --headless --path . --script res://tests/world/generate_island_preview.gd
##
## Instantiates the real game world, waits for procedural art to be generated,
## then saves a snapshot with no running scripts. Never modifies island_01.tscn.
const SOURCE := preload("res://scenes/world/island_01.tscn")
const OUTPUT := "res://scenes/world/island_01_preview.tscn"

func _initialize() -> void:
    call_deferred("_bake")

func _bake() -> void:
    var island := SOURCE.instantiate()
    if island == null:
        push_error("Could not instantiate Island 01")
        quit(1)
        return
    root.add_child(island)
    await process_frame
    await physics_frame

    # PackedScene only saves owned descendants. Procedural runtime children
    # normally have no owner, so explicitly own each by the preview root.
    _prepare_snapshot(island, island)
    _add_preview_cameras(island)

    var snapshot := PackedScene.new()
    var pack_error := snapshot.pack(island)
    if pack_error != OK:
        push_error("Unable to pack Island 01 preview: " + str(pack_error))
        quit(1)
        return
    var save_error := ResourceSaver.save(snapshot, OUTPUT)
    if save_error != OK:
        push_error("Unable to save Island 01 preview: " + str(save_error))
        quit(1)
        return
    print("PASS: Editor preview saved to " + OUTPUT)
    print("Open this preview scene in Godot's 3D editor. Source scene unchanged.")
    quit(0)

func _prepare_snapshot(node: Node, preview_root: Node) -> void:
    # Remove procedural scripts only from the generated snapshot. The original
    # island_01.tscn remains the gameplay source of truth.
    if node.get_script() != null:
        node.set_script(null)
    if node != preview_root:
        node.owner = preview_root
    for child in node.get_children():
        _prepare_snapshot(child, preview_root)

func _add_preview_cameras(island: Node3D) -> void:
    # Saved cameras are visible in the generated scene's node tree.
    # Select one and click Preview in Godot's Inspector/viewport camera toolbar.
    var camera_group := Node3D.new()
    camera_group.name = "PreviewCameras"
    island.add_child(camera_group)
    camera_group.owner = island
    var views := [
        ["01_WholeIsland", Vector3(0, 150, 115), Vector3(0, 0, -5)],
        ["02_BeachLanding", Vector3(34, 37, 78), Vector3(0, 0, 30)],
        ["03_MilitaryOutpost", Vector3(45, 39, -8), Vector3(0, 2, -42)],
        ["04_CoastalSide", Vector3(-116, 90, 80), Vector3(0, 0, 0)],
        ["05_TopDown", Vector3(0, 175, -5), Vector3(0, 0, -5)]
    ]
    for view in views:
        var camera := Camera3D.new()
        camera.name = view[0]
        camera.far = 650.0
        camera.fov = 65.0
        camera_group.add_child(camera)
        camera.owner = island
        camera.global_position = view[1]
        # Top down cannot use UP parallel to the viewing direction.
        var up := Vector3.FORWARD if camera.name == "05_TopDown" else Vector3.UP
        camera.look_at(view[2], up)
