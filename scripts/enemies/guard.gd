extends CharacterBody3D
## AI-001: self-contained guard. The integrator supplies patrol markers and/or a target.
signal alerted(target: Node3D)
signal died
signal health_changed(current: float, maximum: float)
signal attack_performed(target: Node3D, damage: float)

enum State { PATROL, CHASE, ATTACK, SEARCH, DEAD }

@export var max_health: float = 100.0
@export var patrol_speed: float = 2.0
@export var chase_speed: float = 3.5
@export var patrol_arrival_radius: float = 0.5
@export var sight_range: float = 17.0
@export_range(1.0, 360.0, 1.0) var field_of_view_degrees: float = 110.0
@export var eye_height: float = 1.55
@export var attack_range: float = 8.0
@export var attack_damage: float = 10.0
@export var attack_interval: float = 1.2
@export var target_lost_seconds: float = 3.0
@export var search_seconds: float = 2.0
@export var target_group: StringName = &"player"
@export var patrol_points: Array[NodePath] = []
@export var use_navigation: bool = false

var health: float
var state: State = State.PATROL
var target: Node3D
var patrol_index: int = 0
var last_seen_position: Vector3
var _lost_time: float = 0.0
var _search_time: float = 0.0
var _attack_time: float = 0.0
var _gravity: float = 9.8

@onready var navigation_agent: NavigationAgent3D = get_node_or_null("NavigationAgent3D")

func _ready() -> void:
	health = maxf(max_health, 0.0)
	if health <= 0.0:
		_die()
		return
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))

func get_team() -> String:
	return "enemy"

func set_target(value: Node3D) -> void:
	target = value if is_instance_valid(value) and value != self else null

func take_damage(amount: float) -> void:
	if state == State.DEAD or not is_finite(amount) or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_die()

func _die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	target = null
	velocity = Vector3.ZERO
	died.emit()

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_attack_time = maxf(0.0, _attack_time - delta)
	if not is_instance_valid(target):
		target = null
		_acquire_target()
	var visible := can_see_target(target)
	match state:
		State.PATROL:
			if visible:
				_become_alert()
			else:
				_patrol(delta)
		State.CHASE, State.ATTACK:
			if visible:
				last_seen_position = target.global_position
				_lost_time = 0.0
				if global_position.distance_to(target.global_position) <= attack_range:
					state = State.ATTACK
					_stop_horizontal()
					_face(target.global_position)
					_try_attack()
				else:
					state = State.CHASE
					_move_towards(target.global_position, chase_speed, delta)
			else:
				_lost_time += delta
				if _lost_time >= target_lost_seconds:
					state = State.SEARCH
					_search_time = 0.0
					target = null
				else:
					_move_towards(last_seen_position, chase_speed, delta)
		State.SEARCH:
			if visible:
				_become_alert()
			else:
				_search_time += delta
				_move_towards(last_seen_position, patrol_speed, delta)
				if _search_time >= search_seconds:
					state = State.PATROL
					_lost_time = 0.0
	_apply_gravity_and_slide(delta)

func _acquire_target() -> void:
	if target_group == &"":
		return
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group(target_group):
		if candidate is Node3D and candidate != self and is_instance_valid(candidate):
			if candidate.has_method("get_team") and candidate.get_team() == get_team():
				continue
			var distance := global_position.distance_squared_to(candidate.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				target = candidate

func can_see_target(candidate: Node3D) -> bool:
	if state == State.DEAD or not is_instance_valid(candidate) or candidate == self:
		return false
	if candidate.has_method("get_team") and candidate.get_team() == get_team():
		return false
	var origin := global_position + Vector3.UP * eye_height
	var destination := candidate.global_position + Vector3.UP * 1.0
	var direction := destination - origin
	if direction.length() > sight_range or direction.length_squared() < 0.0001:
		return false
	var flat_forward := -global_transform.basis.z
	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	flat_forward.y = 0.0
	if flat_direction.length_squared() > 0.0001 and flat_forward.length_squared() > 0.0001:
		if rad_to_deg(flat_forward.angle_to(flat_direction)) > field_of_view_degrees * 0.5:
			return false
	var query := PhysicsRayQueryParameters3D.create(origin, destination)
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider: Object = hit.get("collider")
	if collider == candidate:
		return true
	if collider is Node:
		return candidate.is_ancestor_of(collider)
	return false

func _become_alert() -> void:
	if not is_instance_valid(target):
		return
	state = State.CHASE
	last_seen_position = target.global_position
	_lost_time = 0.0
	alerted.emit(target)

func _try_attack() -> void:
	if state != State.ATTACK or _attack_time > 0.0 or not can_see_target(target):
		return
	if global_position.distance_to(target.global_position) > attack_range:
		return
	_attack_time = maxf(attack_interval, 0.01)
	var victim := target
	if victim.has_method("take_damage"):
		victim.take_damage(attack_damage)
	attack_performed.emit(victim, attack_damage)

func _patrol(delta: float) -> void:
	if patrol_points.is_empty():
		_stop_horizontal()
		return
	var marker := get_node_or_null(patrol_points[patrol_index % patrol_points.size()]) as Node3D
	if marker == null:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		_stop_horizontal()
		return
	if global_position.distance_to(marker.global_position) <= patrol_arrival_radius:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		marker = get_node_or_null(patrol_points[patrol_index]) as Node3D
	if marker != null:
		_move_towards(marker.global_position, patrol_speed, delta)

func _move_towards(destination: Vector3, speed: float, _delta: float) -> void:
	var waypoint := destination
	if use_navigation and navigation_agent != null and NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) > 0:
		navigation_agent.target_position = destination
		if not navigation_agent.is_navigation_finished():
			waypoint = navigation_agent.get_next_path_position()
	var direction := waypoint - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.01:
		_stop_horizontal()
		return
	direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	_face(waypoint)

func _face(destination: Vector3) -> void:
	var flat := destination - global_position
	flat.y = 0.0
	if flat.length_squared() > 0.001:
		rotation.y = atan2(-flat.x, -flat.z)

func _stop_horizontal() -> void:
	velocity.x = 0.0
	velocity.z = 0.0

func _apply_gravity_and_slide(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
