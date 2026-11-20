extends SceneTree

const Mission = preload("res://scripts/missions/mission_controller.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, detail: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL MISSION-001: " + detail)

func _run() -> void:
	var mission = Mission.new()
	root.add_child(mission)
	var transitions: Array[Array] = []
	mission.mission_state_changed.connect(func(previous: int, current: int): transitions.append([previous, current]))
	check(mission.state == Mission.State.NOT_STARTED, "initial state")
	check(not mission.extract(), "reject extraction before start")
	check(not mission.complete_objective(), "reject objective before start")
	check(not mission.fail_mission(), "reject failure before start")
	check(mission.start_mission(), "start")
	check(not mission.start_mission(), "reject repeated start")
	check(not mission.extract(), "reject early extraction")
	check(mission.complete_objective(), "objective")
	check(not mission.complete_objective(), "reject duplicate objective")
	check(mission.extract(), "extraction after objective")
	check(mission.state == Mission.State.EXTRACTED, "extracted terminal state")
	check(not mission.fail_mission(), "reject failure after extraction")
	check(not mission.start_mission(), "reject restart after extraction")
	check(transitions == [[0, 1], [1, 2], [2, 3]], "signal transitions")
	mission.queue_free()

	var failed = Mission.new()
	root.add_child(failed)
	check(failed.start_mission(), "failure case start")
	check(failed.fail_mission(), "active mission fails")
	check(failed.state == Mission.State.FAILED, "failed terminal state")
	check(not failed.extract(), "cannot extract after failure")
	check(not failed.complete_objective(), "cannot complete after failure")
	check(not failed.fail_mission(), "cannot fail twice")
	failed.queue_free()

	var failed_after_objective = Mission.new()
	root.add_child(failed_after_objective)
	failed_after_objective.start_mission()
	failed_after_objective.complete_objective()
	check(failed_after_objective.fail_mission(), "failure after objective allowed")
	check(not failed_after_objective.extract(), "failed objective cannot extract")
	failed_after_objective.queue_free()

	if failures == 0:
		print("PASS MISSION-001: progression, invalid transitions, failure and terminal states")
	quit(0 if failures == 0 else 1)
