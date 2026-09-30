extends Node

@onready var parent: RigidBody3D = get_parent()

func call_save() -> Dictionary:
	var save_data = {}
	save_data["global_transform"] = parent.global_transform
	save_data["linear_velocity"] = parent.linear_velocity
	save_data["angular_velocity"] = parent.angular_velocity
	save_data["fuel_percentage"] = parent.fuel_percentage
	return save_data

func call_load(data: Dictionary) -> void:
	parent.global_transform = data["global_transform"]
	parent.linear_velocity = data["linear_velocity"]
	parent.angular_velocity = data["angular_velocity"]
	parent.fuel_percentage = data["fuel_percentage"]
