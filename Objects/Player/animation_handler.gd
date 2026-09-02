extends Node

@onready var parent: CharacterBody3D = get_parent()
@onready var animation_tree: AnimationTree = parent.get_node("AnimationTree")
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]

@export var anim_lerp_speed: float = 8.0
@export var air_lerp_speed: float = 6.0

var talking: bool = false
var current_state: String = ""

@export var fishing_rod_mesh: MeshInstance3D
@export var player_hand_ik: CCDIK3D

func _ready() -> void:
	fishing_rod_mesh.visible = false
	player_hand_ik.active = false

func _process(delta: float) -> void:
	handleanim(delta)


func handleanim(delta: float) -> void:
	var horizontal_speed := Vector2(
		parent.velocity.x,
		parent.velocity.z
	).length()

	# --------------------------------
	# GROUNDED / AIRBORNE STATE
	# --------------------------------

	if parent.is_on_floor():
		change_state("Grounded")

		# Grounded BlendSpace
		# -1 = Speak
		#  0 = Idle
		#  1 = Walk

		var target_grounded := 0.0

		if talking:
			target_grounded = -1.0
		elif horizontal_speed > 0.1:
			target_grounded = 1.0
		else:
			target_grounded = 0.0

		var current_grounded: float = animation_tree[
			"parameters/Grounded/blend_position"
		]

		var grounded_weight := 1.0 - exp(-anim_lerp_speed * delta)

		animation_tree[
			"parameters/Grounded/blend_position"
		] = lerp(
			current_grounded,
			target_grounded,
			grounded_weight
		)

	else:
		change_state("Airborne")

		# --------------------------------
		# AIRBORNE BLENDSPACE
		# --------------------------------
		#
		# 0 = Jump
		# 1 = Fall
		#

		# Convert vertical velocity into a smooth
		# Jump -> Fall value.

		var air_target = clamp(
			-remap(parent.velocity.y, 4.0, -4.0, 0.0, 1.0),
			0.0,
			1.0
		)

		var current_air: float = animation_tree[
			"parameters/Airborne/blend_position"
		]

		var air_weight := 1.0 - exp(-air_lerp_speed * delta)

		animation_tree[
			"parameters/Airborne/blend_position"
		] = lerp(
			current_air,
			air_target,
			air_weight
		)


func change_state(new_state: String) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	playback.travel(new_state)


func start_talking() -> void:
	talking = true


func stop_talking() -> void:
	talking = false

func show_rod() -> void:
	fishing_rod_mesh.visible = true

func hide_rod() -> void:
	fishing_rod_mesh.visible = false
