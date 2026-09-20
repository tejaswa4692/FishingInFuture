### Im writing the documentation rn here cuz i have short term memory loss
# When this bouey is spawned ie thrown in the water, first thing it does is initialize the timer with a random 
# wait time, then when That wait time is completed it generates a random numner bw 0 and 100, if that 
# number is more than 30 (70% chance of catching fish this can further be increased for catching fish at night)
# It spawns a random fish on this and then starts applying random imupse
# As of writing this i wanna start another timer if player doesnt react on time and leaves the fish bit
# it can eventually leave the bait and run away 

extends RigidBody3D

var water: WaterPhysics 
@onready var buoyancy_component: Node3D = $BuoyancyComponent
@onready var fish_bite_sound: AudioStreamPlayer3D = $"StardewValleyFishBite!SoundEffect"

var reeling_in: bool = false
var reel_target: Node3D = null
@onready var fish_bite_pos: Marker3D = $FishBitePos
@onready var fish_struggle_time: Timer = $fish_struggle_time

@export var reel_speed: float = 25.0
@export var reel_stop_distance: float = 1.5

@onready var fish_global_: Node3D = $"Fish(Global)"
@onready var fish_timer: Timer = $FishTimer
var is_bit: bool = false
var current_bouey_upgrade = 0
var in_water: bool = false

@onready var bouey_mesh = $Bobber/Sphere #TODO MAKE THIS UPGRADE POSSIBLE IN FUTURE
const BOBBER_MAT_2 = preload("uid://wptswcflmbqn")

func _ready() -> void:
	randomize()
	generate_random_wait_time()
	fish_timer.start()
	buoyancy_component.water = get_tree().get_first_node_in_group("water")


func reel_to(target: Node3D) -> void:
	reeling_in = true
	reel_target = target

func bitecheck() -> void:
	if !is_bit:
		var rng = randi_range(0, 100)
		if rng >= 30: # DEBUG CHANGE LATER [CHANGED]
			is_bit = true
			apply_central_impulse(Vector3(0, -10, 0))
			fish_timer.wait_time = 0.3
		else:
			generate_random_wait_time()
	else:
		if fish_struggle_time.is_stopped():
			fish_struggle_time.wait_time = randi_range(2, 5)
			fish_struggle_time.start()
			if !fish_bite_sound.playing:
				fish_bite_sound.play()
		var random_impulse := Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-10.0, -3.0),
			randf_range(-0.5, 0.5)
		)
		apply_central_impulse(random_impulse)
		fish_timer.wait_time = 0.3
	fish_timer.start()

func _physics_process(_delta: float) -> void:
	if reeling_in and is_instance_valid(reel_target):
		var direction := reel_target.global_position - global_position
		var distance := direction.length()

		if distance <= reel_stop_distance:
			reeling_in = false
			reel_target = null
			player_fishing_anim_reset()
			queue_free()
			return

		linear_velocity = direction.normalized() * reel_speed

 
func player_fishing_anim_reset() -> void:  #idk why i make life harder for myself
	var player = get_tree().get_first_node_in_group("player")
	player.fishing_animation.play("RESET")
	player.player_hand_ik.active = false
	player.fishing_rod_mesh.visible = false
	
	player.player_hand_ik.influence = 0


func fish_has_earned_its_freedom() -> void:
	fish_timer.wait_time = randi_range(5, 20)
	fish_timer.start()
	is_bit = false


func set_bobber_stage(stage: int) -> void:
	var mat: StandardMaterial3D = BOBBER_MAT_2.duplicate()
	var stage_color: Color
	match stage:
		0:
			stage_color = Color.BURLYWOOD
		1:
			stage_color = Color.RED
		2:
			stage_color = Color.BLUE
		3:
			stage_color = Color.GREEN
		_:
			push_warning("set_bobber_stage: unhandled stage %d" % stage)
			return
	mat.albedo_color = stage_color
	bouey_mesh.set_surface_override_material(1, mat)

func generate_random_wait_time() -> void:
	match current_bouey_upgrade:
		0: #Default player spawns with this 
			fish_timer.wait_time = randi_range(10, 15)
		1: # The red upgrade
			fish_timer.wait_time = randi_range(7, 15)
		2: # The blue upgrade
			fish_timer.wait_time = randi_range(5, 10)
		3: # The green upgrade
			fish_timer.wait_time = randi_range(1, 6)
			
