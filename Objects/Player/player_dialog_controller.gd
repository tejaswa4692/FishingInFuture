extends Node

@onready var text_dialog: RichTextLabel = $"../MainUI/TextBox/Panel/RichTextLabel"

signal dialogue_advanced

func start_speaking() -> void:
	text_dialog.get_parent().show()
	get_parent().canmove = false
	while PlayerTextDialog.dialog_awaiting.size() > 0:
		var text_to_show = PlayerTextDialog.dialog_awaiting.pop_front()

		text_dialog.text = text_to_show
		text_dialog.visible_characters = 0

		var char_count := text_dialog.get_total_character_count()

		var tween := create_tween()
		tween.tween_property(
			text_dialog,
			"visible_characters",
			char_count,
			char_count * 0.03
		)

		await tween.finished
		await dialogue_advanced
	get_parent().canmove = true
	text_dialog.get_parent().hide()
	PlayerTextDialog.current_state = PlayerTextDialog.DialogState.WAITING
