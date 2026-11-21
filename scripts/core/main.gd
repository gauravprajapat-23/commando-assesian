extends Node3D

const ISLAND := preload("res://scenes/world/island_01.tscn")
const PLAYER := preload("res://scenes/player/commando.tscn")
const GUARD := preload("res://scenes/enemies/guard.tscn")
const MISSION := preload("res://scripts/missions/mission_controller.gd")
const HUD := preload("res://scenes/ui/mission_hud.tscn")
const WORLD_LAYER := 1
const ACTOR_LAYER := 2

# Debug-only spectator camera: F8 toggle, RMB look, arrows fly, Q/E descend/ascend.
# Does not alter player or mission state, and is inactive until requested.
var spectator_camera: Camera3D
var spectator_enabled := false
var spectator_dragging := false
var spectator_speed := 18.0
const SPECTATOR_SENSITIVITY := 0.003

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		_toggle_spectator()
		get_viewport().set_input_as_handled()
		return
	if not spectator_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		spectator_dragging = event.pressed
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if spectator_dragging else Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and spectator_dragging:
		spectator_camera.rotation.y -= event.relative.x * SPECTATOR_SENSITIVITY
		spectator_camera.rotation.x = clampf(spectator_camera.rotation.x - event.relative.y * SPECTATOR_SENSITIVITY, -1.5, 1.5)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		spectator_speed = minf(spectator_speed * 1.25, 120.0)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		spectator_speed = maxf(spectator_speed / 1.25, 2.0)

func _toggle_spectator() -> void:
	spectator_enabled = not spectator_enabled
	spectator_dragging = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if spectator_enabled:
		if spectator_camera == null:
			spectator_camera = Camera3D.new()
			spectator_camera.name = "SpectatorCamera"
			spectator_camera.far = 450.0
			add_child(spectator_camera)
		var active := get_viewport().get_camera_3d()
		if active != null and active != spectator_camera:
			spectator_camera.global_transform = active.global_transform
		spectator_camera.make_current()
	elif is_instance_valid(player):
		player.get_node("CameraYaw/CameraPitch/Camera3D").make_current()

func _process(delta: float) -> void:
	if not spectator_enabled or spectator_camera == null:
		return
	# Arrows intentionally avoid WASD, which belongs to player movement.
	var x := float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT))
	var z := float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))
	var y := float(Input.is_key_pressed(KEY_E)) - float(Input.is_key_pressed(KEY_Q))
	var direction := spectator_camera.global_basis.x * x + spectator_camera.global_basis.z * z + Vector3.UP * y
	if direction.length_squared() > 0.0:
		spectator_camera.global_position += direction.normalized() * spectator_speed * delta

var player: CharacterBody3D
var mission: CommandoMissionController

func _ready() -> void:
	var island := ISLAND.instantiate() as Node3D
	add_child(island)

	mission = MISSION.new()
	mission.name = "MissionController"
	add_child(mission)
	var overlay := CanvasLayer.new()
	overlay.name = "HUDLayer"
	add_child(overlay)
	var hud := HUD.instantiate()
	overlay.add_child(hud)

	player = PLAYER.instantiate()
	player.name = "Player"
	player.hit_mask = WORLD_LAYER | ACTOR_LAYER
	player.transform = island.get_node("PlayerSpawn").global_transform
	player.add_to_group("player")
	hud.bind_mission(mission)
	hud.bind_player(player)
	player.died.connect(mission.fail_mission)
	add_child(player)
	player.get_node("CameraYaw/CameraPitch/Camera3D").make_current()

	var guards := Node3D.new()
	guards.name = "Guards"
	add_child(guards)
	for marker: Marker3D in island.get_node("EnemySpawns").get_children():
		_spawn_guard(guards, marker)

	_add_zone("ObjectiveZone", island.get_node("ObjectivePoint"), 2.4, mission.complete_objective)
	_add_zone("ExtractionZone", island.get_node("ExtractionPoint"), 3.0, mission.extract)
	mission.start_mission()

func _physics_process(_delta: float) -> void:
	if player.global_position.y < -10.0:
		player.take_damage(player.health)

func _spawn_guard(parent: Node3D, marker: Marker3D) -> void:
	var guard := GUARD.instantiate() as CharacterBody3D
	guard.name = marker.name
	guard.transform = marker.global_transform
	var patrol_paths: Array[NodePath] = []
	for offset: Vector3 in [Vector3.ZERO, Vector3(-signf(marker.position.x) * 3.0, 0, 2.0)]:
		var waypoint := Marker3D.new()
		waypoint.position = marker.global_position + offset - Vector3.UP * 0.5
		parent.add_child(waypoint, true)
		patrol_paths.append(NodePath("../" + String(waypoint.name)))
	guard.patrol_points = patrol_paths
	guard.set_target(player)
	parent.add_child(guard)

func _add_zone(zone_name: String, marker: Marker3D, radius: float, advance: Callable) -> void:
	var zone := Area3D.new()
	zone.name = zone_name
	zone.position = marker.global_position
	zone.collision_layer = 0
	zone.collision_mask = ACTOR_LAYER
	zone.monitorable = false
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	var collider := CollisionShape3D.new()
	collider.shape = sphere
	zone.add_child(collider)
	zone.body_entered.connect(func(body: Node3D) -> void:
		if body == player:
			advance.call()
	)
	add_child(zone)
