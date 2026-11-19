extends Control
## Passive, keyboard-friendly HUD. No absolute scene paths or direct world dependencies.
class_name CommandoMissionHUD

@onready var objective_label: Label = %ObjectiveLabel
@onready var health_label: Label = %HealthLabel
@onready var ammo_label: Label = %AmmoLabel

var _mission: Node
var _player: Node
var _mission_state: int = 0
var _health_current: float = 0.0
var _health_maximum: float = 0.0
var _ammo_current: int = 0
var _ammo_reserve: int = 0
var _has_health := false
var _has_ammo := false

func _ready() -> void:
	_refresh()

func bind_mission(mission: Node) -> void:
	if _mission != null and is_instance_valid(_mission):
		if _mission.mission_state_changed.is_connected(_on_mission_state_changed):
			_mission.mission_state_changed.disconnect(_on_mission_state_changed)
	_mission = mission
	_mission_state = 0
	if mission != null:
		_mission_state = int(mission.state)
		mission.mission_state_changed.connect(_on_mission_state_changed)
	_refresh()

func bind_player(player: Node) -> void:
	if _player != null and is_instance_valid(_player):
		if _player.health_changed.is_connected(_on_health_changed):
			_player.health_changed.disconnect(_on_health_changed)
		if _player.ammo_changed.is_connected(_on_ammo_changed):
			_player.ammo_changed.disconnect(_on_ammo_changed)
	_player = player
	_has_health = false
	_has_ammo = false
	if player != null:
		player.health_changed.connect(_on_health_changed)
		player.ammo_changed.connect(_on_ammo_changed)
		# Initial values should be pushed by the Player after binding;
		# otherwise the HUD reports unavailable instead of inventing numbers.
	_refresh()

func _exit_tree() -> void:
	bind_mission(null)
	bind_player(null)

func _on_mission_state_changed(_previous: int, next_state: int) -> void:
	_mission_state = next_state
	_refresh()

func _on_health_changed(current: float, maximum: float) -> void:
	_health_current = current
	_health_maximum = maximum
	_has_health = true
	_refresh()

func _on_ammo_changed(current: int, reserve: int) -> void:
	_ammo_current = current
	_ammo_reserve = reserve
	_has_ammo = true
	_refresh()

func _refresh() -> void:
	if not is_node_ready():
		return
	const OBJECTIVES := [
		"Mission not started",
		"Infiltrate the enemy outpost",
		"Objective complete — reach extraction",
		"Mission complete — extracted",
		"Mission failed"
	]
	objective_label.text = "OBJECTIVE: " + OBJECTIVES[clampi(_mission_state, 0, OBJECTIVES.size() - 1)]
	health_label.text = "HEALTH: %d / %d" % [roundi(_health_current), roundi(_health_maximum)] if _has_health else "HEALTH: --"
	ammo_label.text = "AMMO: %d / %d" % [_ammo_current, _ammo_reserve] if _has_ammo else "AMMO: --"
