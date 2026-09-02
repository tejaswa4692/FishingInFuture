extends RigidBody3D

var water: WaterPhysics 
@onready var buoyancy_component: Node3D = $BuoyancyComponent
var player = null
var canControl: bool = false
@onready var mount_point: Marker3D = $MountPoint
var in_water: bool = false
@onready var save_script: Node = $save_script

func _ready() -> void:
	buoyancy_component.water = get_tree().get_first_node_in_group("water")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player = null
