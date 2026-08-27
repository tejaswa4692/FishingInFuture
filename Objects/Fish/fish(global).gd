extends Node3D

@export var scenes: Array[PackedScene] = []
var fish 

func _ready() -> void:
	fish = null
	randomize()

func spawn_random_fish() -> void:
	var randomindex = randi_range(0, len(scenes)) - 1
	spawnfish(scenes[randomindex])
	fish = scenes[randomindex]
	print(fish, "Global fishes")

func spawnfish(fish: PackedScene) -> void:
	var fish_instance := fish.instantiate() as Node3D
	fish_instance.global_rotation_degrees.x = 90
	add_child(fish_instance)
