extends SceneTree
## PLAYER-ANIM-03: validates installed external GLB's rig and animation mapping.
## With no optional GLB installed, reports SKIP (procedural fallback remains valid).
const PLAYER := preload("res://scenes/player/commando.tscn")
const ASSET := "res://assets/characters/commando.glb"
var failures := 0

func _check(ok: bool, detail: String) -> void:
    if ok:
        print("PASS PLAYER-ANIM-03: " + detail)
    else:
        failures += 1
        push_error("FAIL PLAYER-ANIM-03: " + detail)

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    if not ResourceLoader.exists(ASSET):
        print("SKIP PLAYER-ANIM-03: Optional rigged GLB not installed. Run tools/install_commando_starter.ps1.")
        quit(0)
        return
    var actor := PLAYER.instantiate()
    root.add_child(actor)
    await process_frame
    var visual := actor.get_node("BodyVisual")
    var report: Dictionary = visual.get_import_report()
    _check(bool(report.get("imported", false)), "GLB model was imported instead of procedural fallback")
    _check(int(report.get("bones", 0)) > 10, "skinned humanoid skeleton has bones")
    var clips: Dictionary = report.get("clips", {})
    for name in ["idle", "walk", "run"]:
        _check(clips.has(name), "locomotion clip mapped: " + name)
    if bool(report.get("imported", false)):
        visual.animate_character(0.016, 0.0, false, false, false, false, false)
        _check(visual.get_animation_state() == "idle", "idle state plays")
        visual.animate_character(0.016, 1.0, false, false, false, false, false)
        _check(visual.get_animation_state() == "walk", "walk state plays")
        visual.animate_character(0.016, 1.0, true, false, false, false, false)
        _check(visual.get_animation_state() == "run", "run state plays")
    actor.queue_free()
    await process_frame
    quit(0 if failures == 0 else 1)
