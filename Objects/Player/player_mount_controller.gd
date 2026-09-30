extends Node

@onready var parent = get_parent()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("mount"):
		if !parent.canControl:
			if parent.player == null:
				return
			parent.canControl = true
			parent.fuel_guage.show()
			parent.player.mount(parent, parent.mount_point)
			parent.init_fuel_percentage()
			if parent.get_meta("vehicle", "") == "jetski":
				parent.hide_player()
		else:
			if parent.player == null:
				return
			parent.canControl = false
			parent.player.unmount()
			parent.fuel_guage.hide()
			parent.init_fuel_percentage()
			if parent.get_meta("vehicle", "") == "jetski":
				parent.show_player()
