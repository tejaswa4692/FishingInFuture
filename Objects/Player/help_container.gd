extends Control

signal helpadvanced

@onready var helps = [$Help1, $Help2, $Help3]
var current_help := 0

func _ready() -> void:
	hide()

func _input(_sevent: InputEvent) -> void:
	if not Input.is_action_just_pressed("HelpOpen"):
		return

	if not visible:
		show()
		current_help = 0
		show_help(current_help)
	else:
		current_help += 1

		if current_help >= helps.size():
			hide()
			current_help = 0
		else:
			show_help(current_help)

func show_help(index: int) -> void:
	for i in range(helps.size()):
		helps[i].visible = i == index
