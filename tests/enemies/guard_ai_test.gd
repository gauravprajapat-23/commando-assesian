extends SceneTree
## Execute: godot --headless --path . --script res://tests/enemies/guard_ai_test.gd
const GUARD_SCENE := preload("res://scenes/enemies/guard.tscn")
const GUARD_SCRIPT := preload("res://scripts/enemies/guard.gd")
var failures := 0

class DummyTarget:
	extends CharacterBody3D
	var damage_received := 0.0
	func get_team() -> String:
		return "player"
	func take_damage(amount: float) -> void:
		damage_received += amount

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL AI-001: " + message)
	else:
		print("PASS AI-001: " + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	var guard := GUARD_SCENE.instantiate() as CharacterBody3D
	guard.position = Vector3.ZERO
	root.add_child(guard)
	guard.set_physics_process(false)
	var target := DummyTarget.new()
	target.position = Vector3(0, 0, -4)
	root.add_child(target)
	await physics_frame
	_assert(guard.get_team() == "enemy", "team contract")
	_assert(guard is CharacterBody3D, "CharacterBody3D scene root")
	guard.set_target(target)
	_assert(guard.can_see_target(target), "visible unobstructed target")
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 3, 0.5)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0, 1, -2)
	root.add_child(wall)
	await physics_frame
	_assert(not guard.can_see_target(target), "wall obstructs line of sight")
	wall.queue_free()
	await physics_frame
	var first := Marker3D.new()
	first.name = "PatrolA"
	first.position = Vector3(0, 0, -3)
	guard.add_child(first)
	var second := Marker3D.new()
	second.name = "PatrolB"
	second.position = Vector3(0, 0, 3)
	guard.add_child(second)
	guard.patrol_points = [NodePath("PatrolA"), NodePath("PatrolB")]
	guard._patrol(0.016)
	_assert(guard.patrol_index == 0 and guard.velocity.z < 0.0, "patrol heads toward first point")
	first.position = Vector3.ZERO
	guard._patrol(0.016)
	_assert(guard.patrol_index == 1, "patrol advances at waypoint")
	var alerted_count := [0]
	guard.alerted.connect(func(_node: Node3D) -> void: alerted_count[0] += 1)
	guard._become_alert()
	_assert(guard.state == GUARD_SCRIPT.State.CHASE and alerted_count[0] == 1, "alert transition and signal")
	guard.target_lost_seconds = 0.05
	guard.search_seconds = 0.05
	guard.set_target(null)
	guard.target_group = &""
	guard._physics_process(0.06)
	_assert(guard.state == GUARD_SCRIPT.State.SEARCH, "target loss transitions into search")
	guard._physics_process(0.06)
	_assert(guard.state == GUARD_SCRIPT.State.PATROL, "search returns to patrol")
	guard.set_target(target)
	guard.state = GUARD_SCRIPT.State.ATTACK
	guard._attack_time = 0.0
	guard._try_attack()
	_assert(target.damage_received > 0.0, "attack damages valid visible target")
	var attacks := [0]
	guard.attack_performed.connect(func(_node: Node3D, _amount: float) -> void: attacks[0] += 1)
	var deaths := [0]
	guard.died.connect(func() -> void: deaths[0] += 1)
	guard.take_damage(guard.health + 1.0)
	guard._attack_time = 0.0
	guard._try_attack()
	guard._physics_process(0.5)
	_assert(guard.state == GUARD_SCRIPT.State.DEAD and deaths[0] == 1, "lethal damage emits died once")
	_assert(attacks[0] == 0, "no attacks after death")
	guard.take_damage(10.0)
	_assert(deaths == 1, "dead guard cannot die twice")
	root.queue_free()
	await process_frame
	if failures == 0:
		print("AI-001 focused tests PASSED")
	quit(0 if failures == 0 else 1)
