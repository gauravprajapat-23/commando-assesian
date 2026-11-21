extends SceneTree
## PLAYER-ANIM-02: animation clip discovery and lifecycle without external GLB.
const PLAYER := preload("res://scenes/player/commando.tscn")
var failures := 0

func _check(condition: bool, detail: String) -> void:
    if condition:
        print("PASS PLAYER-ANIM-02: " + detail)
    else:
        failures += 1
        push_error("FAIL PLAYER-ANIM-02: " + detail)

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var player = PLAYER.instantiate()
    root.add_child(player)
    await process_frame
    var visual = player.get_node("BodyVisual")
    _check(visual.has_method("play_action"), "visual exposes action animation hooks")
    _check(visual.has_method("get_animation_state"), "visual exposes current animation")
    if visual.get_node_or_null("ImportedCommando") == null:
        visual.play_action("fire")
        _check(visual.fallback_fire > 0.0, "procedural fire recoil triggers")
        visual.animate_character(0.016, 0.0, false, true, false, false, false)
        visual.play_action("reload")
        _check(visual.fallback_reload > 0.0, "procedural reload pose triggers")
        visual.animate_character(0.016, 0.0, false, false, false, false, true)
        visual.play_action("death")
        _check(visual.has_died, "procedural death state latches")
    # Standalone dummy rig tests imported clip aliases without bundling a model.
    var dummy := AnimationPlayer.new()
    dummy.name = "DummyAnimationPlayer"
    visual.add_child(dummy)
    var library := AnimationLibrary.new()
    for label in ["Idle", "Walk", "Running", "Crouch", "Aim", "Reload", "Shoot", "Death"]:
        var animation := Animation.new()
        animation.length = 1.0
        library.add_animation(label, animation)
    dummy.add_animation_library("", library)
    visual.animation_player = dummy
    visual.animation_clips.clear()
    visual.active_animation = ""
    visual.has_died = false
    visual._detect_animations()
    for state in ["idle", "walk", "run", "crouch", "aim", "reload", "fire", "death"]:
        _check(visual.animation_clips.has(state), "recognizes " + state + " animation")
    visual._animate_imported(0.016, 0.0, false, false, false, false, false)
    _check(visual.get_animation_state() == "idle", "idle selected when standing")
    visual._animate_imported(0.016, 1.0, false, false, false, false, false)
    _check(visual.get_animation_state() == "walk", "walk selected when moving")
    visual._animate_imported(0.016, 1.0, true, false, false, false, false)
    _check(visual.get_animation_state() == "run", "run selected when sprinting")
    visual._animate_imported(0.016, 0.0, false, true, false, false, false)
    _check(visual.get_animation_state() == "aim", "aim selected when stationary")
    visual.play_action("reload")
    visual._animate_imported(0.016, 0.0, false, false, false, false, true)
    _check(visual.get_animation_state() == "reload", "reload overrides movement")
    visual.play_action("death")
    visual._animate_imported(0.016, 0.0, false, false, false, true, false)
    _check(visual.get_animation_state() == "death", "death takes priority")
    player.queue_free()
    await process_frame
    quit(0 if failures == 0 else 1)
