extends Camera3D
## Developer preview camera. No addon or input-map configuration required.
## F8 is owned by main.gd; this camera handles only preview controls.

const LOOK_SENSITIVITY := 0.003
const MIN_PITCH := -1.48
const MAX_PITCH := 1.48
const MIN_DISTANCE := 6.0
const MAX_DISTANCE := 330.0

var preview_active := false
var orbit_mode := true
var drag_button := 0
var focus_point := Vector3(0.0, 0.0, -5.0)
var orbit_distance := 155.0
var orbit_yaw := 0.0
var orbit_pitch := 0.85
var fly_speed := 30.0
var help_label: Label

func _ready() -> void:
    far = 600.0
    _create_help()

func _create_help() -> void:
    var layer := CanvasLayer.new()
    layer.name = "CameraPreviewGuide"
    add_child(layer)
    help_label = Label.new()
    help_label.name = "Controls"
    help_label.position = Vector2(18, 120)
    help_label.add_theme_color_override("font_color", Color(1, 1, 1))
    help_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
    help_label.add_theme_constant_override("shadow_offset_x", 2)
    help_label.add_theme_constant_override("shadow_offset_y", 2)
    layer.add_child(help_label)
    _update_help()

func _update_help() -> void:
    if help_label == null:
        return
    help_label.visible = preview_active
    if preview_active:
        var mode := "ORBIT" if orbit_mode else "FREE FLY"
        help_label.text = "WORLD PREVIEW - " + mode + "\nF8: player | C: orbit/free | 1-4: views | Home: overview\nDrag left/right mouse: rotate | Wheel: zoom/speed\n" + ("Middle drag: pan | " if orbit_mode else "") + "WASD/Arrows: move | Q/E: down/up"

func set_active(value: bool) -> void:
    preview_active = value
    drag_button = 0
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _update_help()

func set_preset(number: int) -> void:
    orbit_mode = true
    match number:
        1:
            focus_point = Vector3(0, 0, -5)
            global_position = Vector3(0, 150, 115)
        2:
            focus_point = Vector3(0, 0, 30)
            global_position = Vector3(34, 37, 78)
        3:
            focus_point = Vector3(0, 2, -42)
            global_position = Vector3(45, 39, -8)
        4:
            focus_point = Vector3(0, 0, 0)
            global_position = Vector3(-116, 90, 80)
        _:
            return
    var offset: Vector3 = global_position - focus_point
    orbit_distance = clampf(offset.length(), MIN_DISTANCE, MAX_DISTANCE)
    orbit_yaw = atan2(offset.x, offset.z)
    orbit_pitch = asin(clampf(offset.y / orbit_distance, -1.0, 1.0))
    _update_orbit()
    _update_help()

func _update_orbit() -> void:
    var horizontal: float = cos(orbit_pitch) * orbit_distance
    global_position = focus_point + Vector3(sin(orbit_yaw) * horizontal, sin(orbit_pitch) * orbit_distance, cos(orbit_yaw) * horizontal)
    look_at(focus_point, Vector3.UP)

func _toggle_mode() -> void:
    orbit_mode = not orbit_mode
    if orbit_mode:
        focus_point = global_position - global_basis.z * orbit_distance
        var offset := global_position - focus_point
        orbit_yaw = atan2(offset.x, offset.z)
        orbit_pitch = asin(clampf(offset.y / offset.length(), -1.0, 1.0))
        _update_orbit()
    _update_help()

func _input(event: InputEvent) -> void:
    if not preview_active:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1, KEY_KP_1:
                set_preset(1)
            KEY_2, KEY_KP_2:
                set_preset(2)
            KEY_3, KEY_KP_3:
                set_preset(3)
            KEY_4, KEY_KP_4:
                set_preset(4)
            KEY_HOME:
                set_preset(1)
            KEY_C:
                _toggle_mode()
            _:
                return
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton:
        if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
            if event.pressed:
                drag_button = event.button_index
            elif drag_button == event.button_index:
                drag_button = 0
            # Only capture while dragging, so mouse interaction is discoverable.
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if drag_button != 0 else Input.MOUSE_MODE_VISIBLE
            get_viewport().set_input_as_handled()
        elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
            var zoom_factor := 0.82 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.22
            if orbit_mode:
                orbit_distance = clampf(orbit_distance * zoom_factor, MIN_DISTANCE, MAX_DISTANCE)
                _update_orbit()
            else:
                fly_speed = clampf(fly_speed / zoom_factor, 3.0, 150.0)
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseMotion and drag_button != 0:
        if orbit_mode:
            if drag_button == MOUSE_BUTTON_MIDDLE:
                var motion: InputEventMouseMotion = event as InputEventMouseMotion
                var lateral: Vector3 = global_basis.x * (-motion.relative.x) + global_basis.y * motion.relative.y
                focus_point += lateral * orbit_distance * 0.0015
            else:
                orbit_yaw -= event.relative.x * LOOK_SENSITIVITY
                orbit_pitch = clampf(orbit_pitch + event.relative.y * LOOK_SENSITIVITY, 0.04, MAX_PITCH)
            _update_orbit()
        else:
            rotation.y -= event.relative.x * LOOK_SENSITIVITY
            rotation.x = clampf(rotation.x - event.relative.y * LOOK_SENSITIVITY, MIN_PITCH, MAX_PITCH)
        get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
    if not preview_active:
        return
    var x := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
    var z := float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
    var y := float(Input.is_key_pressed(KEY_E)) - float(Input.is_key_pressed(KEY_Q))
    var direction: Vector3 = global_basis.x * x + global_basis.z * z + Vector3.UP * y
    if direction.length_squared() == 0.0:
        return
    var speed := fly_speed * (2.5 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
    if orbit_mode:
        focus_point += direction.normalized() * speed * delta
        _update_orbit()
    else:
        global_position += direction.normalized() * speed * delta

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and preview_active:
        drag_button = 0
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
