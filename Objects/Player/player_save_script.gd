extends Node

@onready var parent: CharacterBody3D = get_parent()

func call_save():
	var save_data = {}
	save_data["global_transform"] = parent.global_transform
	save_data["bobber_upgrade"] = parent.current_bobber_upgrade
	save_data["bubble_tex"] = parent.bubbles_counter.text
	save_data["player_current_hat"] = parent.player_cosmetic_manager.current_hat
	return save_data

func call_load(data: Dictionary) -> void:
	parent.global_transform = data["global_transform"]
	parent.current_bobber_upgrade = data["bobber_upgrade"]
	parent.bubbles_counter.text = data["bubble_tex"]
	parent.player_cosmetic_manager.current_hat = data["player_current_hat"]
