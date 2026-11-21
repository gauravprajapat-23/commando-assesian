extends SceneTree
## Verify world camera framing and mouse-driven orbit independently of GUI renderer.
const CAMERA_SCRIPT := preload("res://scripts/core/world_preview_camera.gd")
var failures := 0

func _check(ok: bool, description: String) -> void:
    if ok:
        print("PASS CAMERA-PREVIEW: " + description)
    else:
        failures += 1
        push_error("FAIL CAMERA-PREVIEW: " + description)

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var holder := Node3D.new()
    root.add_child(holder)
    var camera := CAMERA_SCRIPT.new() as Camera3D
    camera.name = "WorldPreviewCamera"
    holder.add_child(camera)
    await process_frame
    camera.set_active(true)

    for number in range(1, 5):
        camera.set_preset(number)
        _check(camera.orbit_mode, "preset " + str(number) + " uses orbit mode")
        _check(camera.orbit_distance >= camera.MIN_DISTANCE, "preset " + str(number) + " has valid distance")
        var target_direction: Vector3 = (camera.focus_point - camera.global_position).normalized()
        var forward: Vector3 = -camera.global_basis.z
        _check(forward.dot(target_direction) > 0.999, "preset " + str(number) + " frames target")

    camera.set_preset(1)
    var original := camera.global_position
    var drag := InputEventMouseButton.new()
    drag.button_index = MOUSE_BUTTON_LEFT
    drag.pressed = true
    camera._input(drag)
    var move := InputEventMouseMotion.new()
    move.relative = Vector2(80, 20)
    camera._input(move)
    _check(camera.global_position.distance_to(original) > 0.1, "mouse drag rotates orbit camera")
    var release := InputEventMouseButton.new()
    release.button_index = MOUSE_BUTTON_LEFT
    release.pressed = false
    camera._input(release)

    camera._toggle_mode()
    _check(not camera.orbit_mode, "free fly mode toggles")
    camera._toggle_mode()
    _check(camera.orbit_mode, "orbit mode restores")
    camera.set_active(false)
    _check(not camera.preview_active, "camera deactivates cleanly")
    quit(0 if failures == 0 else 1)
