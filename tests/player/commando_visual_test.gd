extends SceneTree
## PLAYER-VISUAL-01: character composition, collision and animation contract.
const PLAYER := preload("res://scenes/player/commando.tscn")
var failures := 0

func _check(value: bool, detail: String) -> void:
    if value:
        print("PASS PLAYER-VISUAL-01: " + detail)
    else:
        failures += 1
        push_error("FAIL PLAYER-VISUAL-01: " + detail)

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var player = PLAYER.instantiate()
    root.add_child(player)
    await process_frame
    var visual := player.get_node_or_null("BodyVisual") as Node3D
    _check(visual != null, "body visual is attached")
    _check(player.get_node_or_null("CollisionShape3D") is CollisionShape3D, "original physics collider intact")
    _check(player.get_node_or_null("CameraYaw/CameraPitch/Camera3D") is Camera3D, "camera hierarchy intact")
    if visual != null:
        _check(visual.has_method("animate_character"), "walk animation controller attached")
        _check(visual.get_node_or_null("ImportedCommando") != null or visual.get_node_or_null("TacticalUpperBody") != null, "player has full tactical model")
        if visual.get_node_or_null("ImportedCommando") == null:
            for part in [
                "TacticalUpperBody/Head", "TacticalUpperBody/HelmetShell",
                "TacticalUpperBody/ArmoredVest", "TacticalUpperBody/Backpack",
                "TacticalUpperBody/RifleVisual", "LeftLeg/LBoot", "RightLeg/RBoot",
                "LeftArm/LGlove", "RightArm/RGlove"
            ]:
                _check(visual.get_node_or_null(part) is MeshInstance3D or visual.get_node_or_null(part) is Node3D, part + " exists")
            visual.call("animate_character", 0.15, 1.0, false, false, false, false)
            var left_leg := visual.get_node_or_null("LeftLeg") as Node3D
            _check(left_leg != null and absf(left_leg.rotation.x) > 0.001, "walk animation moves a leg")
    _check(player.has_method("try_fire") and player.has_method("take_damage"), "combat contracts preserved")
    player.queue_free()
    await process_frame
    quit(0 if failures == 0 else 1)
