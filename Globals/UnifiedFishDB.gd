extends Node

var fish_db = {}

func _ready() -> void:
	load_database()

func load_database() -> void:
	var file := FileAccess.open("res://Globals/fish_db.json", FileAccess.READ)
	if file == null:
		push_error("Could not open fish database.")
		return
	var json = JSON.parse_string(file.get_as_text())
	
	if json is Dictionary:
		fish_db = json
	else:
		push_error("Fish database JSON is invalid.")

func get_fish(id: String) -> Dictionary:
	return fish_db.get(id, {})

func get_fish_json_via_path(fish_scene_path: String) -> Variant:
	for fish_id in fish_db:
		var fish_data: Dictionary = fish_db[fish_id]
		if fish_data.get("scene", "") == fish_scene_path:
			return fish_data
	return null

func return_cost_via_path(fish_scene_path: String) -> int:
	for fish_id in fish_db:
		var fish_data: Dictionary = fish_db[fish_id]
		if fish_data.get("scene", "") == fish_scene_path:
			return fish_data.get("price", 0)
	return 0

func return_min_max_weight(fish_scene_path: String) -> Array:
	for fish_id in fish_db:
		var fish_data: Dictionary = fish_db[fish_id]
		if fish_data.get("scene", "") == fish_scene_path:
			var min_weight = fish_data.get("weight").get("min")
			var max_weight = fish_data.get("weight").get("max")
			return [min_weight, max_weight]
	return [0, 0]

func generate_random_fish_data(fish_scene_path: String) -> Dictionary:
	var fish_data = get_fish_json_via_path(fish_scene_path)
	if fish_data == null:
		return {}
	var weight_data: Dictionary = fish_data.get("weight", {})
	var min_weight: int = weight_data.get("min", 0.0)
	var max_weight: int = weight_data.get("max", 0.0)
	var random_weight := randi_range(min_weight, max_weight)
	return {
		"display_name": fish_data.get("display_name", ""),
		"price": fish_data.get("price", 0),
		"scene": fish_data.get("scene", ""),
		"rarity": fish_data.get("rarity", ""),
		"weight": random_weight
	}
