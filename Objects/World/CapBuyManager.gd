extends Node3D

var player = null
var current_hat = null

var hat_lookup_table: Dictionary = {
	"Angler Hat" : 100,
	"Regular Cap" : 200,
	"Floral Hat" : 1000,
	"Wizard Hat" : 250,
	"WW1 Helmet" : 150
}

func _ready() -> void:
	for area in get_tree().get_nodes_in_group("hat_buy_area"):
		area.body_entered.connect(_on_hat_entered.bind(area))
		area.body_exited.connect(_on_hat_exited.bind(area))

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_action_just_pressed("debug_speak") and player != null and current_hat != null:
			if inventory.playerTotalHoldingCost >= hat_lookup_table[current_hat]:
				var prompt = "Would you like to buy %s? This would cost you %s dabloons? (Y/N) keys" % [
					current_hat,
					hat_lookup_table[current_hat]
				]
				var confirmed = await PlayerTextDialog.ask_yes_no([prompt])
				if confirmed:
					player.player_cosmetic_manager.current_hat = current_hat
					inventory.playerTotalHoldingCost -= hat_lookup_table[current_hat]
				else:
					PlayerTextDialog.add_dialog([r"Feel free to look around :)"])
			else:
				var prompt = "Aww this hat costs " + str(hat_lookup_table[current_hat]) +  " you cant afford it yet, maybe come back w more dabloons?"
				PlayerTextDialog.add_dialog([prompt])


func _on_hat_entered(body: Node3D, area: Area3D) -> void:
	if body.is_in_group("player"):
		player = body
		current_hat = area.get_meta("hat_name", "")


func _on_hat_exited(body: Node3D, _area: Area3D) -> void:
	if body.is_in_group("player"):
		player = null
		current_hat = null
