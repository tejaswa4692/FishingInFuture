extends Node

@onready var parent = get_parent()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("mount"):
		if !parent.canControl:
			if parent.player == null:
				return
			parent.canControl = true
			parent.player.mount(parent, parent.mount_point)
		else:
			if parent.player == null:
				return
			parent.canControl = false
			parent.player.unmount()
