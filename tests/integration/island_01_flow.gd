extends SceneTree

const MAIN := preload("res://scenes/main.tscn")
const MISSION := preload("res://scripts/missions/mission_controller.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS INTEGRATION-001: " + description)
	else:
		failures += 1
		push_error("FAIL INTEGRATION-001: " + description)

func _move_until(player: CharacterBody3D, direction: Vector2, condition: Callable, frames: int) -> void:
	player.set_control_state({"move": direction, "sprint": true})
	for frame in range(frames):
		if condition.call():
			break
		await physics_frame
	player.set_control_state({})

func _run() -> void:
	var game := MAIN.instantiate()
	root.add_child(game)
	var player: CharacterBody3D = game.player
	var mission: CommandoMissionController = game.mission
	var hud := game.get_node("HUDLayer/MissionHUD")
	var guard: CharacterBody3D = game.get_node("Guards/GuardA")
	_check(player.position.distance_to(Vector3(0, 0.5, 37)) < 0.01, "player uses beach spawn")
	_check(root.get_camera_3d() == player.get_node("CameraYaw/CameraPitch/Camera3D"), "player camera is active")
	_check(guard.target == player and guard.patrol_points.size() == 2, "guard target and patrol are wired")
	_check(hud.health_label.text.contains("100 / 100") and hud.ammo_label.text.contains("30 / 90"), "initial HUD signals are visible")
	await _move_until(player, Vector2.LEFT, func() -> bool: return player.position.x < -23.0, 260)
	_check(player.position.x < -23.0 and mission.state == MISSION.State.INFILTRATE, "walking to extraction before the objective does not finish the mission")
	await _move_until(player, Vector2.RIGHT, func() -> bool: return player.position.x >= 0.0, 260)
	await _move_until(player, Vector2.UP, func() -> bool: return mission.state != MISSION.State.INFILTRATE, 950)
	_check(mission.state == MISSION.State.OBJECTIVE_COMPLETE, "traversing from beach to outpost triggers the objective")
	await _move_until(player, Vector2.DOWN, func() -> bool: return player.position.z >= 37.0, 950)
	await _move_until(player, Vector2.LEFT, func() -> bool: return mission.state == MISSION.State.EXTRACTED, 260)
	_check(mission.state == MISSION.State.EXTRACTED and hud.objective_label.text.contains("extracted"), "returning to beach triggers extraction and updates the HUD")
	game.queue_free()
	await process_frame

	game = MAIN.instantiate()
	root.add_child(game)
	player = game.player
	hud = game.get_node("HUDLayer/MissionHUD")
	guard = game.get_node("Guards/GuardA")
	player.set_control_state({})
	player.position = Vector3(-12, 0.1, -36)
	guard.look_at(Vector3(-12, guard.position.y, -36))
	for frame in range(15):
		await physics_frame
	_check(player.health < player.max_health and hud.health_label.text.contains(str(roundi(player.health))), "guard encounter damages player and updates health HUD")
	player.camera.look_at(guard.global_position + Vector3.UP)
	_check(player.try_fire() and guard.health < guard.max_health and hud.ammo_label.text.contains("29 / 90"), "player shot hits actual guard and updates ammo HUD")
	player.take_damage(player.health)
	_check(game.mission.state == MISSION.State.FAILED and hud.objective_label.text.contains("failed"), "player death fails the mission and updates the HUD")
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
