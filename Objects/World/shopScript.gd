extends Node3D

var player = null

#[{ "display_name": "Yellow Fish", "price": 150.0, "scene": "res://Assets/Fishes/YellowFish/YellowFish.glb", "rarity": "uncommon", "weight": 17 }]

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debugsellall"):
		if player != null:
			var calculated_price = 0
			for i in inventory.playerInventory:
				var fish_price = i.get("price", 0)
				var fish_weight = i.get("weight", 0)
				calculated_price = fish_price * fish_weight
				inventory.playerTotalHoldingCost += calculated_price
				
				inventory.player.bubbles_counter.text = "Bubbles: " + str(inventory.playerTotalHoldingCost)
			player.display_sold(calculated_price)
			#PlayerTextDialog.add_dialog(["Thx for choosing us :) Your total is " + str(calculated_price) + " I hope to see u again :)"
			#])
			#get_viewport().set_input_as_handled()
			inventory.playerInventory.clear()
			
	if Input.is_action_just_pressed("debug_speak") and PlayerTextDialog.current_state == PlayerTextDialog.DialogState.WAITING and player != null:
		PlayerTextDialog.add_dialog([
			"Hi :)",
			"I am the humble shopkeeper",
			"Press C to sell your fishes to me :)"
		])
		
		get_viewport().set_input_as_handled()

func _player_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body


func _player_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = null
