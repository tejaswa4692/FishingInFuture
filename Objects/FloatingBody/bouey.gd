extends RigidBody3D

var water: WaterPhysics 
@onready var buoyancy_component: Node3D = $BuoyancyComponent

var reeling_in: bool = false
var reel_target: Node3D = null
@onready var fish_bite_pos: Marker3D = $FishBitePos

@export var reel_speed: float = 25.0
@export var reel_stop_distance: float = 1.5

@onready var fish_global_: Node3D = $"Fish(Global)"
@onready var fish_timer: Timer = $FishTimer
var is_bit: bool = false

func _ready() -> void:
	randomize()
	fish_timer.wait_time = 5
	fish_timer.start()
	buoyancy_component.water = get_tree().get_first_node_in_group("water")


func reel_to(target: Node3D) -> void:
	reeling_in = true
	reel_target = target

func bitecheck() -> void:
	if !is_bit:
		var rng = randi_range(0, 100)
		if rng >= 0: # DEBUG CHANGE LATER
			is_bit = true
			apply_central_impulse(Vector3(0, -10, 0))
			fish_timer.wait_time = 0.3
		else:
			fish_timer.wait_time = 5
	else:
		var random_impulse := Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-10.0, -3.0),
			randf_range(-0.5, 0.5)
		)

		apply_central_impulse(random_impulse)
		fish_timer.wait_time = 0.3

	fish_timer.start()

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
