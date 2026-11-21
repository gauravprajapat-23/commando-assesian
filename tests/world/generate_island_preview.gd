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
