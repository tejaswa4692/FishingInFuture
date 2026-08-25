extends Node

const BOUEY = preload("res://Objects/FloatingBody/bouey.tscn")

@onready var player = get_parent()

var current_bouey: RigidBody3D = null


func spawn_booey() -> void:
	current_bouey = BOUEY.instantiate()
	current_bouey.global_position = player.bouey_spawner.global_position
	get_tree().root.add_child(current_bouey)

	var direction = -player.bouey_spawner.global_transform.basis.z + Vector3.UP * 0.5
	current_bouey.apply_central_impulse(direction.normalized() * 3.0)

func reel_back_in() -> void:
	if is_instance_valid(current_bouey):
		current_bouey.reel_to(player)
		player.casted = false
