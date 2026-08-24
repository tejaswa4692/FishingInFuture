extends Node3D

@export var sensitivity: float = 0.005
@export var invert_x: bool = false
@export var invert_y: bool = false
@export var min_pitch_deg: float = 0.0
@export var max_pitch_deg: float = 50.0

@onready var camera_pivot_x: Node3D = $CameraPivotX

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var dir_x := -1.0 if invert_x else 1.0
		rotate_y(-event.relative.x * sensitivity * dir_x)
		var dir_y := -1.0 if invert_y else 1.0
		var new_pitch = camera_pivot_x.rotation_degrees.x + event.relative.y * sensitivity * 57.2958 * dir_y
		camera_pivot_x.rotation_degrees.x = clamp(new_pitch, min_pitch_deg, max_pitch_deg)
