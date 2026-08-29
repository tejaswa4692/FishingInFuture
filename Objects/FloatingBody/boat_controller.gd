extends Node

@onready var parent: RigidBody3D = get_parent()

@export var thrust_force: float = 5.0
@export var reverse_force: float = 5.0
@export var turn_torque: float = 2.0

func _physics_process(_delta: float) -> void:
	if parent.canControl:
		handleMovement()

func handleMovement() -> void:
	var throttle := Input.get_axis("down", "up")
	if throttle > 0 and parent.in_water:
		parent.apply_central_force(-parent.global_transform.basis.z * thrust_force * throttle)
	elif throttle < 0 and parent.in_water:
		parent.apply_central_force(-parent.global_transform.basis.z * reverse_force * throttle)
		
	var steering := Input.get_axis("right", "left")
	
	if steering != 0:
		parent.apply_torque(Vector3.UP * steering * turn_torque)
