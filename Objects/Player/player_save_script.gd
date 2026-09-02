extends Node

@onready var parent: CharacterBody3D = get_parent()

func call_save():
	var save_data = {}
	save_data["global_transform"] = parent.global_transform
	save_data["fishing_rod_tier"] = parent.fishing_rod_tier
	save_data["bubble_tex"] = parent.bubbles_counter.text
	return save_data

func call_load(data: Dictionary) -> void:
	parent.global_transform = data["global_transform"]
	parent.fishing_rod_tier = data["fishing_rod_tier"]
	parent.bubbles_counter.text = data["bubble_tex"]
