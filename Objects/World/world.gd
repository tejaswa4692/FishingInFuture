extends Node3D
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@export var daynightcyclespeed := 10.0
@onready var clown_fish: Node3D = $ClownFish

func _ready() -> void:
	clown_fish.get_node("AnimationPlayer").play("ArmatureAction")
#func _process(delta: float) -> void:
	#sun.rotation_degrees.x = fmod(
		#sun.rotation_degrees.x + daynightcyclespeed * delta,
		#360.0
	#)
	#
	#
	#if sun.rotation_degrees.x < 180.0:
		#Almighty.current_time = Almighty.TimeOfDay.NIGHT
	#else:
		#Almighty.current_time = Almighty.TimeOfDay.MORNING
