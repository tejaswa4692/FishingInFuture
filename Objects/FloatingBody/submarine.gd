extends RigidBody3D

var in_water: bool = false
@onready var buoyancy_component: Node3D = $BuoyancyComponent
var thrust_strength = 1
var torque_strength = 0.005
var canControl: bool = false
var player = null
@onready var mount_point: Marker3D = $MountPoint

func _ready() -> void:
	buoyancy_component.water = get_tree().get_first_node_in_group("water")

#func _physics_process(delta: float) -> void:
	#var local_forward: Vector3 = global_transform.basis.x  # or -basis.z, see note below
	#apply_central_force(local_forward * thrust_strength)
	#apply_torque(Vector3(0, torque_strength, 0))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player = null
