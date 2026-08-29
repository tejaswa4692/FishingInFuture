extends Node3D

@export var sensitivity: float = 0.005
@export var invert_x: bool = false
@export var invert_y: bool = false
@export var min_pitch_deg: float = 0.0
@export var max_pitch_deg: float = 50.0
@export var min_dist_camera: float = 5.0
@export var max_dist_camera: float = 50.0
@onready var camera_pivot_x: Node3D = $CameraPivotX
@onready var camera_arm: SpringArm3D = $CameraPivotX/CameraArm
@onready var camera_3d: Camera3D = $CameraPivotX/CameraArm/Camera3D
@onready var color_rect: ColorRect = $CameraPivotX/CameraArm/Camera3D/ColorRect

func _ready() -> void:
	color_rect.hide()

func _process(delta: float) -> void:
	if camera_3d.global_position.y <= -5.217:
		color_rect.show()
	else:
		color_rect.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var dir_x := -1.0 if invert_x else 1.0
		rotate_y(-event.relative.x * sensitivity * dir_x)
		var dir_y := -1.0 if invert_y else 1.0
		var new_pitch = camera_pivot_x.rotation_degrees.x + event.relative.y * sensitivity * 57.2958 * dir_y
		camera_pivot_x.rotation_degrees.x = clamp(new_pitch, min_pitch_deg, max_pitch_deg)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_arm.spring_length = clamp(camera_arm.spring_length + 0.5, min_dist_camera, max_dist_camera)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_arm.spring_length = clamp(camera_arm.spring_length - 0.5, min_dist_camera, max_dist_camera)
