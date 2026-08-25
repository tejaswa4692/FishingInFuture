extends RigidBody3D

var water: WaterPhysics 
@onready var buoyancy_component: Node3D = $BuoyancyComponent

var reeling_in: bool = false
var reel_target: Node3D = null

@export var reel_speed: float = 25.0
@export var reel_stop_distance: float = 1.5



func _ready() -> void:
	buoyancy_component.water = get_tree().get_first_node_in_group("water")


func reel_to(target: Node3D) -> void:
	reeling_in = true
	reel_target = target


func _physics_process(delta: float) -> void:
	if reeling_in and is_instance_valid(reel_target):
		var direction := reel_target.global_position - global_position
		var distance := direction.length()

		if distance <= reel_stop_distance:
			reeling_in = false
			reel_target = null
			queue_free()
			return

		linear_velocity = direction.normalized() * reel_speed
