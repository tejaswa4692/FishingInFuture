extends Node
class_name JumpController

@export var jump_velocity: float = 10.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0

func update(body: CharacterBody3D, delta: float) -> void:
	_coyote_timer = coyote_time if body.is_on_floor() else _coyote_timer - delta
	_buffer_timer = jump_buffer_time if Input.is_action_just_pressed("jump") else _buffer_timer - delta

	if _buffer_timer > 0.0 and _coyote_timer > 0.0:
		body.velocity.y = jump_velocity
		_buffer_timer = 0.0
		_coyote_timer = 0.0
