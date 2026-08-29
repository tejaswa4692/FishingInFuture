extends Node

@onready var text_dialog: RichTextLabel = $"../MainUI/TextBox/Panel/RichTextLabel"

signal dialogue_advanced


func start_speaking() -> void:
	text_dialog.get_parent().show()

	while PlayerTextDialog.dialog_awaiting.size() > 0:
		
		var text_to_show = PlayerTextDialog.dialog_awaiting.pop_front()
		print(text_to_show)
		text_dialog.text = text_to_show

		await dialogue_advanced

	text_dialog.get_parent().hide()

	PlayerTextDialog.current_state = PlayerTextDialog.DialogState.WAITING
