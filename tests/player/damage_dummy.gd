extends StaticBody3D

var damage_received: float = 0.0
var team: String = "enemy"

func take_damage(amount: float) -> void:
    damage_received += amount

func get_team() -> String:
    return team
