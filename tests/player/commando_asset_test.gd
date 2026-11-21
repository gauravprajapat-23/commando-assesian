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
    # Protect imported-model clip selection from the ambiguous suffix bug.
    if clips.has("idle"):
        _check(String(clips["idle"]).to_lower().ends_with("idle"), "idle uses an idle animation")
    if clips.has("walk"):
        _check(not String(clips["walk"]).to_lower().contains("crouch"), "walk does not use crouch walk")
    if clips.has("crouch_walk"):
        _check(String(clips["crouch_walk"]).to_lower().contains("crouch"), "crouch locomotion selects crouch clip")
    if bool(report.get("imported", false)):
        var model := visual.get_node_or_null("ImportedCommando")
        _check(model != null, "imported model present under BodyVisual")
        var anim_player := visual.animation_player as AnimationPlayer
        _check(anim_player != null, "AnimationPlayer was discovered")
        if anim_player != null:
            var bone_tracks := 0
            for clip in anim_player.get_animation_list():
                var animation := anim_player.get_animation(StringName(clip))
                if animation == null:
                    continue
                for i in range(animation.get_track_count()):
                    var kind := animation.track_get_type(i)
                    if kind == Animation.TYPE_POSITION_3D or kind == Animation.TYPE_ROTATION_3D or kind == Animation.TYPE_SCALE_3D:
                        if String(animation.track_get_path(i)).contains(":"):
                            bone_tracks += 1
            _check(bone_tracks > 0, "animation clips contain skeleton bone transform tracks")
        visual.animate_character(0.016, 0.0, false, false, false, false, false)
        _check(visual.get_animation_state() == "idle", "idle state plays")
        visual.animate_character(0.016, 1.0, false, false, false, false, false)
        _check(visual.get_animation_state() == "walk", "walk state plays")
        visual.animate_character(0.016, 1.0, true, false, false, false, false)
        _check(visual.get_animation_state() == "run", "run state plays")
    actor.queue_free()
    await process_frame
    quit(0 if failures == 0 else 1)
