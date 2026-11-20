extends SceneTree
## Run: godot --headless --path . --script res://tests/player/test_commando.gd

const PLAYER_SCENE = preload("res://scenes/player/commando.tscn")
const DUMMY_SCRIPT = preload("res://tests/player/damage_dummy.gd")

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _check(condition: bool, detail: String) -> void:
    if not condition:
        failures.append(detail)
        push_error("FAIL PLAYER-001: " + detail)

func _run() -> void:
    var player = PLAYER_SCENE.instantiate()
    root.add_child(player)
    await process_frame
    _check(player is CharacterBody3D, "root must be CharacterBody3D")
    _check(player.get_team() == "player", "player team contract")
    _check(player.has_signal("health_changed") and player.has_signal("ammo_changed") and player.has_signal("died"), "signal contract")
    var health_events: Array = []
    var ammo_events: Array = []
    var deaths: Array = []
    player.health_changed.connect(func(current, maximum): health_events.append([current, maximum]))
    player.ammo_changed.connect(func(current, reserve): ammo_events.append([current, reserve]))
    player.died.connect(func(): deaths.append(true))

    player.set_control_state({"move": Vector2(1, 0), "sprint": true, "aim": false})
    _check(player._external_controls, "injected control enabled")
    _check(player._control_state.get("move") == Vector2(1, 0), "injected move retained")
    player.inject_look(0.2, 0.1)
    _check(absf(player.camera_yaw.rotation.y - 0.2) < 0.01, "injected camera yaw")
    player.clear_control_override()
    _check(not player._external_controls, "native input restoration")
    player.set_control_state({}) # stop keyboard/mouse during test

    var enemy = DUMMY_SCRIPT.new()
    enemy.collision_layer = 1
    enemy.collision_mask = 0
    var shape := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 0.8
    shape.shape = sphere
    enemy.add_child(shape)
    root.add_child(enemy)
    enemy.global_position = player.camera.global_position - player.camera.global_basis.z * 8.0
    await physics_frame
    await physics_frame

    _check(player.ammo == 30 and player.reserve_ammo == 90, "initial ammo")
    _check(player.try_fire(), "first shot accepted")
    _check(player.ammo == 29, "shot consumes one round")
    _check(absf(enemy.damage_received - player.weapon_damage) < 0.01, "hitscan damages enemy")
    _check(not player.try_fire(), "fire rate cooldown enforced")
    player.tick_combat(player.fire_interval + 0.01)
    _check(player.try_fire(), "shot after cooldown accepted")
    _check(player.ammo == 28, "second shot consumes one round")

    enemy.team = "player"
    player.tick_combat(player.fire_interval + 0.01)
    var before: float = enemy.damage_received
    _check(player.try_fire(), "friendly hit still consumes shot")
    _check(enemy.damage_received == before, "friendly fire blocked")
    _check(player.start_reload(), "reload starts")
    _check(not player.try_fire(), "fire blocked while reloading")
    player.tick_combat(player.reload_duration + 0.01)
    _check(not player.is_reloading, "reload completed")
    _check(player.ammo == 30 and player.reserve_ammo == 87, "reload transfers correct reserve amount")
    _check(not player.start_reload(), "full magazine cannot reload")
    _check(ammo_events.size() >= 4, "ammo_changed emitted for shooting and reload")

    player.take_damage(25.0)
    _check(player.health == 75.0, "damage decreases health")
    _check(health_events.size() == 1 and health_events[0] == [75.0, 100.0], "health_changed carries current and maximum")
    player.take_damage(-5.0)
    _check(player.health == 75.0, "negative damage ignored")
    player.take_damage(1000.0)
    _check(player.health == 0.0 and player.is_dead, "lethal damage clamps at zero")
    _check(deaths.size() == 1, "died emitted exactly once")
    player.take_damage(10.0)
    _check(deaths.size() == 1 and not player.try_fire(), "dead player cannot shoot or die twice")
    enemy.queue_free()
    player.queue_free()
    await process_frame
    if failures.is_empty():
        print("PASS PLAYER-001: scene, injected controls, aim, hitscan, friendly fire, cooldown, ammo, reload, damage and death")
        quit(0)
    else:
        print("FAIL PLAYER-001: %d checks failed: %s" % [failures.size(), str(failures)])
        quit(1)
