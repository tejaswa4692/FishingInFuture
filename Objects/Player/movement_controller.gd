extends Node
class_name MovementController

@export var speed: float = 8.0
@export var acceleration: float = 20.0
@export var friction: float = 25.0
@export var air_control: float = 0.5
@export var rotation_speed: float = 10.0
@export_range(-180.0, 180.0, 1.0) var mesh_forward_offset_deg: float = 90.0

func update(body: CharacterBody3D, delta: float, camera_ref: Node3D) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	).normalized()

	var cam_basis := camera_ref.global_transform.basis
	var cam_forward := -cam_basis.z
	var cam_right := cam_basis.x
	cam_forward.y = 0.0
	cam_right.y = 0.0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var target_velocity := (cam_right * input_dir.x + cam_forward * -input_dir.y) * speed
	var horizontal := Vector3(body.velocity.x, 0, body.velocity.z)

	if input_dir.length() > 0.01:
		var accel := acceleration if body.is_on_floor() else acceleration * air_control
		horizontal = horizontal.move_toward(target_velocity, accel * delta)
	else:
		var frict := friction if body.is_on_floor() else friction * air_control
		horizontal = horizontal.move_toward(Vector3.ZERO, frict * delta)

	body.velocity.x = horizontal.x
	body.velocity.z = horizontal.z

func face_direction(body: CharacterBody3D, mesh: Node3D, delta: float) -> void:
	var horizontal := Vector3(body.velocity.x, 0, body.velocity.z)
	if horizontal.length() > 0.1:
		var target_angle := atan2(-horizontal.x, -horizontal.z) + deg_to_rad(mesh_forward_offset_deg)
		mesh.rotation.y = lerp_angle(mesh.rotation.y, target_angle, rotation_speed * delta)
