extends SceneTree

const Mission = preload("res://scripts/missions/mission_controller.gd")
const HUD = preload("res://scenes/ui/mission_hud.tscn")

class MockPlayer extends Node:
	signal health_changed(current: float, maximum: float)
	signal ammo_changed(current: int, reserve: int)

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, detail: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL HUD-001: " + detail)

func _run() -> void:
	var mission = Mission.new()
	var player = MockPlayer.new()
	var hud = HUD.instantiate()
	root.add_child(mission)
	root.add_child(player)
	root.add_child(hud)
	await process_frame
	hud.bind_mission(mission)
	hud.bind_player(player)
	check(hud.objective_label.text.contains("not started"), "initial objective")
	check(hud.health_label.text == "HEALTH: --", "unknown health")
	check(hud.ammo_label.text == "AMMO: --", "unknown ammo")
	player.health_changed.emit(77.0, 100.0)
	player.ammo_changed.emit(12, 48)
	check(hud.health_label.text == "HEALTH: 77 / 100", "health signal")
	check(hud.ammo_label.text == "AMMO: 12 / 48", "ammo signal")
	mission.start_mission()
	check(hud.objective_label.text.contains("Infiltrate"), "infiltration UI")
	mission.complete_objective()
	check(hud.objective_label.text.contains("extraction"), "objective complete UI")
	mission.extract()
	check(hud.objective_label.text.contains("extracted"), "extracted UI")

	hud.bind_player(null)
	check(hud.health_label.text == "HEALTH: --", "reset health after unbind")
	check(hud.ammo_label.text == "AMMO: --", "reset ammo after unbind")
	player.health_changed.emit(1.0, 2.0)
	check(hud.health_label.text == "HEALTH: --", "old player disconnected")
	hud.bind_mission(null)
	check(hud.objective_label.text.contains("not started"), "reset mission after unbind")

	var fail = Mission.new()
	root.add_child(fail)
	hud.bind_mission(fail)
	fail.start_mission()
	fail.fail_mission()
	check(hud.objective_label.text.contains("failed"), "failure UI")
	fail.queue_free()
	hud.queue_free()
	player.queue_free()
	mission.queue_free()
	if failures == 0:
		print("PASS HUD-001: objective, health, ammo, failure, and disconnect")
	quit(0 if failures == 0 else 1)
