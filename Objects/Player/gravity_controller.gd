extends Node
class_name GravityController

@export var gravity: float = 20.0
@export var max_fall_speed: float = 40.0

func apply_gravity(body: CharacterBody3D, delta: float) -> void:
	if body.is_on_floor():
		if body.velocity.y < 0.0:
			body.velocity.y = -0.5
	else:
		body.velocity.y = max(body.velocity.y - gravity * delta, -max_fall_speed)
