extends Node3D

const ISLAND := preload("res://scenes/world/island_01.tscn")
const PLAYER := preload("res://scenes/player/commando.tscn")
const GUARD := preload("res://scenes/enemies/guard.tscn")
const MISSION := preload("res://scripts/missions/mission_controller.gd")
const HUD := preload("res://scenes/ui/mission_hud.tscn")
const WORLD_LAYER := 1
const ACTOR_LAYER := 2

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
