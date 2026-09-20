extends Node
var player = null
var playerInWhich = 0

const UPGRADE_PROMPTS: Dictionary = {
	1: "Would you like to purchase the red upgrade for 500 dabloons? This will increase your catch rate by 20%. (Y/N) keys",
	2: "Would you like to purchase the blue upgrade for 1000 dabloons? This will increase your catch rate by 40% (Y/N) keys",
	3: "Would you like to purchase the green upgrade for 1500 dabloons? This will increase your rod catch rate by 50% (Y/N) keys",
}

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_speak") and player != null:
		try_purchase(playerInWhich)

func try_purchase(which: int) -> void:
	if not UPGRADE_PROMPTS.has(which):
		return
	var confirmed: bool = await PlayerTextDialog.ask_yes_no([UPGRADE_PROMPTS[which]])
	if confirmed:
		match which:
			1:
				if inventory.playerTotalHoldingCost > 500:
					buy_red_upgrade()
				else:
					PlayerTextDialog.add_dialog(["Sorry u cant afford it rn :("])
			2:
				if inventory.playerTotalHoldingCost > 1000:
					buy_blue_upgrade()
				else:
					PlayerTextDialog.add_dialog(["Sorry u cant afford it rn :("])
			3:
				if inventory.playerTotalHoldingCost > 1500:
					buy_green_upgrade()
				else:
					PlayerTextDialog.add_dialog(["Sorry u cant afford it rn :("])

func buy_red_upgrade() -> void:
	if player.current_bobber_upgrade < 1:
		inventory.playerTotalHoldingCost -= 200
		player.current_bobber_upgrade = 1
	else:
		PlayerTextDialog.add_dialog(["You already have a better upgrade"])

func buy_blue_upgrade() -> void:
	print(player.current_bobber_upgrade)
	if player.current_bobber_upgrade < 2:
		inventory.playerTotalHoldingCost -= 300
		player.current_bobber_upgrade = 2
	else:
		PlayerTextDialog.add_dialog(["You already have a better upgrade"])

func buy_green_upgrade() -> void:
	print(player.current_bobber_upgrade)
	if player.current_bobber_upgrade < 3:
		inventory.playerTotalHoldingCost -= 500
		player.current_bobber_upgrade = 3
	else:
		PlayerTextDialog.add_dialog(["You already have a better upgrade"])


func red_upgrade_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body
		playerInWhich = 1

func _on_red_upgrade_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = null
		playerInWhich = 0

func _on_blue_upgrade_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body
		playerInWhich = 2

func _on_blue_upgrade_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = null
		playerInWhich = 0

func _on_green_upgrade_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body
		playerInWhich = 3

func _on_green_upgrade_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = null
		playerInWhich = 0
