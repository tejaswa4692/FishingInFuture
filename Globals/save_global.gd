extends Node

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_save"):
		save()
	if Input.is_action_just_pressed("debug_load"):
		load_game()

func save() -> void:
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var savenodes_data = {}
	var save_nodes = get_tree().get_nodes_in_group("saveable")
	for i in save_nodes:
		var node_info = i.save_script.call_save()
		savenodes_data[str(i.get_path())] = node_info
	
	savenodes_data["player_inventory"] = inventory.playerInventory
	savenodes_data["playerTotalHoldingCost"] = inventory.playerTotalHoldingCost
	
	save_file.store_var(savenodes_data)
	save_file.close()
	print("Saved to: ", ProjectSettings.globalize_path("user://savegame.save"))

func load_game() -> void:
	if not FileAccess.file_exists("user://savegame.save"):
		print("No save file found.")
		return
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var savenodes_data = save_file.get_var()
	save_file.close()
	var save_nodes = get_tree().get_nodes_in_group("saveable")
	for i in save_nodes:
		var path = str(i.get_path())
		if savenodes_data.has(path):
			i.save_script.call_load(savenodes_data[path])
	
	inventory.playerInventory = savenodes_data["player_inventory"] 
	inventory.playerTotalHoldingCost = savenodes_data["playerTotalHoldingCost"] 
