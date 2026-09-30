extends Node

# Note for me
# Lets  say that a fuel tank holds 100 gallons (both vehicles)
# And lets put the price of 1 gallon to br 4 dabloons
# So in that a full tank of gas is 400 which is pretty balanced imo
# Lets implement this logic now :yay:

# This was a debugging nightmare...


var player = null
var dialogs: Array[String] = ["Oh hi would you like me to refuel your vehicle?"]
@onready var parent = get_parent()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_action_just_pressed("debug_speak") and player != null and len(parent.vehicles_in) > 0 and PlayerTextDialog.current_state == PlayerTextDialog.DialogState.WAITING:
			var calculated_fuel_to_buy = 0
			for i in parent.vehicles_in:
				calculated_fuel_to_buy +=  100 - i.fuel_percentage # Lets say theres 30 fuel left so we need to fill 100 - 30 = 70 in the tank
			
			var lines: Array[String] = [dialogs[0]]
			lines.append(
				"Alright, that'll be %d dabloons for %d gallons of fuel. (Y/N)" % [
					int(calculated_fuel_to_buy * 4),
					int(calculated_fuel_to_buy)
				]
			)
			var accepted = await PlayerTextDialog.ask_yes_no(lines)
			if accepted:
				if inventory.playerTotalHoldingCost >= calculated_fuel_to_buy * 4:
					print("ka ching")
					inventory.playerTotalHoldingCost -= int(calculated_fuel_to_buy * 4)
					refuel_all_vehicles()
					
				else:
					PlayerTextDialog.add_dialog(["Hmm you dont have enough balance to buy "])
				
			else:
				PlayerTextDialog.add_dialog(["Ah no probs! See u later : D"])
		elif Input.is_action_just_pressed("debug_speak") and player != null and PlayerTextDialog.current_state == PlayerTextDialog.DialogState.WAITING:
			PlayerTextDialog.add_dialog(["wtf did u swim here"])
	



func refuel_all_vehicles() -> void:
	for i in parent.vehicles_in:
		i.fuel_percentage = 100 


func _on_npc_talk_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body


func _on_npc_talk_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = null
