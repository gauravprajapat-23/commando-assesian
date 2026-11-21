extends CharacterBody3D
## PLAYER-001: self-contained, injectable third-person controller.
class_name CommandoController

signal health_changed(current: float, maximum: float)
signal ammo_changed(current: int, reserve: int)
signal died

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.5
@export var crouch_speed: float = 2.5
@export var jump_velocity: float = 5.0
@export var gravity: float = 18.0
@export var mouse_sensitivity: float = 0.0025
@export var max_health: float = 100.0
@export var magazine_size: int = 30
@export var starting_reserve: int = 90
@export var fire_interval: float = 0.12
@export var reload_duration: float = 1.5
@export var weapon_range: float = 120.0
@export var weapon_damage: float = 20.0
@export_flags_3d_physics var hit_mask: int = 1

@onready var camera_yaw: Node3D = $CameraYaw
@onready var camera_pitch: Node3D = $CameraYaw/CameraPitch
@onready var camera: Camera3D = $CameraYaw/CameraPitch/Camera3D
@onready var standing_collider: CollisionShape3D = $CollisionShape3D
@onready var body_visual: Node3D = $BodyVisual

var health: float = 100.0
var ammo: int = 30
var reserve_ammo: int = 90
var is_dead: bool = false
var is_reloading: bool = false
var _reload_left: float = 0.0
var _shot_cooldown: float = 0.0
var _pitch_angle: float = 0.0
# Main scene disables these flags during F8 spectator inspection.
var mouse_look_enabled: bool = true
var spectator_input_disabled: bool = false
var _external_controls: bool = false
var _control_state: Dictionary = {}
var _base_collider_height: float = 1.8

func _ready() -> void:
    health = maxf(max_health, 0.0)
    ammo = maxi(magazine_size, 0)
    reserve_ammo = maxi(starting_reserve, 0)
    if standing_collider.shape is CapsuleShape3D:
        standing_collider.shape = standing_collider.shape.duplicate()
        _base_collider_height = (standing_collider.shape as CapsuleShape3D).height
    health_changed.emit(health, max_health)
    ammo_changed.emit(ammo, reserve_ammo)

## Supports touch, AI, or automated tests without editing project.godot.
## State keys: move (Vector2), jump, sprint, crouch, aim, fire, reload.
func set_control_state(state: Dictionary) -> void:
    _external_controls = true
    _control_state = state.duplicate()

func clear_control_override() -> void:
    _external_controls = false
    _control_state.clear()

## Allow touch aim to inject orbit deltas in radians.
func inject_look(delta_yaw: float, delta_pitch: float) -> void:
    camera_yaw.rotate_y(delta_yaw)
    _pitch_angle = clampf(_pitch_angle + delta_pitch, -1.15, 1.05)
    camera_pitch.rotation.x = _pitch_angle

func _unhandled_input(event: InputEvent) -> void:
    if is_dead or _external_controls or not mouse_look_enabled or spectator_input_disabled:
        return
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        inject_look(-event.relative.x * mouse_sensitivity, -event.relative.y * mouse_sensitivity)

func _native_state() -> Dictionary:
    # No world movement, aim or gunfire while F8 spectator camera is active.
    if spectator_input_disabled:
        return {"move": Vector2.ZERO, "jump": false, "sprint": false, "crouch": false, "aim": false, "fire": false, "reload": false}
    # Physical key polling requires no project InputMap modifications.
    var move := Vector2(
        float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
        float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
    )
    return {
        "move": move.limit_length(),
        "jump": Input.is_key_pressed(KEY_SPACE),
        "sprint": Input.is_key_pressed(KEY_SHIFT),
        "crouch": Input.is_key_pressed(KEY_CTRL),
        "aim": Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT),
        "fire": Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),
        "reload": Input.is_key_pressed(KEY_R)
    }

func _physics_process(delta: float) -> void:
    tick_combat(delta)
    if is_dead:
        velocity = Vector3.ZERO
        return
    var controls: Dictionary = _control_state if _external_controls else _native_state()
    var raw_move: Vector2 = controls.get("move", Vector2.ZERO)
    var move_input := raw_move.limit_length()
    var crouched: bool = bool(controls.get("crouch", false))
    _set_crouched(crouched)
    var forward := -camera_yaw.global_basis.z
    var right := camera_yaw.global_basis.x
    var desired := right * move_input.x + forward * -move_input.y
    desired.y = 0.0
    desired = desired.normalized() * move_input.length()
    var speed := crouch_speed if crouched else (sprint_speed if bool(controls.get("sprint", false)) and not bool(controls.get("aim", false)) else walk_speed)
    velocity.x = desired.x * speed
    velocity.z = desired.z * speed
    if is_on_floor():
        if bool(controls.get("jump", false)) and not crouched:
            velocity.y = jump_velocity
        elif velocity.y < 0.0:
            velocity.y = -0.1
    else:
        velocity.y -= gravity * delta
    move_and_slide()
    if desired.length_squared() > 0.001:
        body_visual.rotation.y = lerp_angle(body_visual.rotation.y, atan2(-desired.x, -desired.z) - rotation.y, minf(1.0, delta * 12.0))
    if bool(controls.get("reload", false)):
        start_reload()
    if bool(controls.get("fire", false)):
        try_fire()

func _set_crouched(enabled: bool) -> void:
    # Keep the collision capsule bottom at ground level.
    if not (standing_collider.shape is CapsuleShape3D):
        return
    var capsule := standing_collider.shape as CapsuleShape3D
    var target_height := maxf(capsule.radius * 2.0, _base_collider_height * (0.65 if enabled else 1.0))
    # Do not stand up into overhead geometry.
    if not enabled and capsule.height < _base_collider_height:
        var clearance := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * (capsule.height - 0.1), global_position + Vector3.UP * (_base_collider_height + 0.1), hit_mask, [get_rid()])
        if not get_world_3d().direct_space_state.intersect_ray(clearance).is_empty():
            return
    capsule.height = target_height
    standing_collider.position.y = target_height * 0.5

func tick_combat(delta: float) -> void:
    _shot_cooldown = maxf(0.0, _shot_cooldown - maxf(0.0, delta))
    if is_reloading:
        _reload_left -= maxf(0.0, delta)
        if _reload_left <= 0.0:
            finish_reload()

func try_fire() -> bool:
    if is_dead or is_reloading or ammo <= 0 or _shot_cooldown > 0.0:
        return false
    ammo -= 1
    _shot_cooldown = maxf(fire_interval, 0.0)
    ammo_changed.emit(ammo, reserve_ammo)
    var origin := camera.global_position
    var destination := origin - camera.global_basis.z * weapon_range
    var query := PhysicsRayQueryParameters3D.create(origin, destination, hit_mask, [get_rid()])
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        var target: Object = hit.get("collider")
        if target != null and target.has_method("take_damage"):
            var friendly := target.has_method("get_team") and str(target.call("get_team")) == get_team()
            if not friendly:
                target.call("take_damage", weapon_damage)
    return true

func start_reload() -> bool:
    if is_dead or is_reloading or ammo >= magazine_size or reserve_ammo <= 0:
        return false
    is_reloading = true
    _reload_left = maxf(reload_duration, 0.0)
    if _reload_left <= 0.0:
        finish_reload()
    return true

func finish_reload() -> void:
    if not is_reloading:
        return
    var transfer: int = mini(maxi(magazine_size - ammo, 0), reserve_ammo)
    ammo += transfer
    reserve_ammo -= transfer
    is_reloading = false
    _reload_left = 0.0
    ammo_changed.emit(ammo, reserve_ammo)

func take_damage(amount: float) -> void:
    if is_dead or not is_finite(amount) or amount <= 0.0:
        return
    health = maxf(0.0, health - amount)
    health_changed.emit(health, max_health)
    if health <= 0.0:
        is_dead = true
        is_reloading = false
        died.emit()

func get_team() -> String:
    return "player"
