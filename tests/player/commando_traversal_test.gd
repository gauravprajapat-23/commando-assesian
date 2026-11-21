extends SceneTree
## PLAYER-MOVE-02: real island collision route from beach to objective approach.
const ISLAND := preload("res://scenes/world/island_01.tscn")
const PLAYER := preload("res://scenes/player/commando.tscn")
var failures := 0

func _check(ok: bool, reason: String) -> void:
    if ok:
        print("PASS PLAYER-MOVE-02: " + reason)
    else:
        failures += 1
        push_error("FAIL PLAYER-MOVE-02: " + reason)

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var island := ISLAND.instantiate() as Node3D
    root.add_child(island)
    var player := PLAYER.instantiate() as CharacterBody3D
    player.global_position = island.get_node("PlayerSpawn").global_position
    root.add_child(player)
    player.set_control_state({"move": Vector2.UP, "sprint": true})
    await physics_frame
    var start: Vector3 = player.global_position
    var stuck_frames := 0
    var max_stuck_frames := 0
    var previous: Vector3 = player.global_position
    var reached := false
    for frame in range(700):
        await physics_frame
        if player.global_position.z < -46.0:
            reached = true
            break
        if frame > 30 and player.is_on_floor():
            var horizontal_delta := Vector2(player.global_position.x - previous.x, player.global_position.z - previous.z).length()
            if horizontal_delta < 0.005:
                stuck_frames += 1
            else:
                stuck_frames = 0
            max_stuck_frames = maxi(max_stuck_frames, stuck_frames)
        previous = player.global_position
    player.set_control_state({})
    _check(start.z > 30.0, "starts at beach spawn")
    _check(reached, "uninterrupted center route reaches past objective")
    _check(max_stuck_frames < 25, "player does not become trapped on route")
    _check(not player.is_dead, "without guards traversal does not end in death")
    _check(player.position.y > -2.0, "player does not fall through terrain")
    print("PLAYER-MOVE-02: final position=", player.global_position, " max stopped ticks=", max_stuck_frames)
    player.queue_free()
    island.queue_free()
    await process_frame
    quit(0 if failures == 0 else 1)
