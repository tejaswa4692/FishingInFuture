extends Node

@onready var parent: RigidBody3D = get_parent()

@export var thrust_force: float = 5.0
@export var reverse_force: float = 5.0
@export var turn_torque: float = 2.0

@export var visual_mesh: Node3D
@export var lean_axis: Vector3 = Vector3(0, 0, 1)
@export var pitch_axis: Vector3 = Vector3(1, 0, 0)
@export var max_lean_deg: float = 15.0
@export var max_pitch_deg: float = 8.0
@export var lean_speed: float = 4.0
@export var top_speed: float = 10.0

var lean: float = 0.0
var pitch: float = 0.0
var restBasis: Basis

func _ready() -> void:
	if visual_mesh:
		restBasis = visual_mesh.transform.basis

func _physics_process(delta: float) -> void:
	if parent.canControl:
		handleMovement(delta)

func handleMovement(delta: float) -> void:
	var throttle := Input.get_axis("down", "up")
	if throttle > 0 and parent.in_water:
		parent.apply_central_force(-parent.global_transform.basis.z * thrust_force * throttle)
	elif throttle < 0 and parent.in_water:
		parent.apply_central_force(-parent.global_transform.basis.z * reverse_force * throttle)
	var steering := Input.get_axis("right", "left")
	if steering != 0:
		parent.apply_torque(Vector3.UP * steering * turn_torque)
	updateTilt(steering, delta)

func updateTilt(steering: float, delta: float) -> void:
	if not visual_mesh:
		return
	lean = lerp_angle(lean, deg_to_rad(max_lean_deg) * -steering, lean_speed * delta)
	var speed := parent.linear_velocity.dot(-parent.global_transform.basis.z)
	pitch = deg_to_rad(max_pitch_deg) * clamp(speed / top_speed, 0.0, 1.0)
	visual_mesh.transform.basis = restBasis.rotated(lean_axis.normalized(), lean).rotated(pitch_axis.normalized(), pitch)
