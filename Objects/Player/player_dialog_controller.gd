extends Node
@onready var text_dialog: RichTextLabel = $"../MainUI/TextBox/Panel/RichTextLabel"
@onready var panel: Control = $"../MainUI/TextBox/Panel"
signal dialogue_advanced

func pop_in() -> void:
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.6, 0.6)
	panel.modulate.a = 0.0
	var pop_tween := create_tween()
	pop_tween.set_ease(Tween.EASE_OUT)
	pop_tween.set_trans(Tween.TRANS_BACK)
	pop_tween.tween_property(panel, "scale", Vector2.ONE, 0.25)
	pop_tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.15)
	await pop_tween.finished

func pop_out() -> void:
	panel.pivot_offset = panel.size / 2.0
	var close_tween := create_tween()
	close_tween.set_ease(Tween.EASE_IN)
	close_tween.set_trans(Tween.TRANS_BACK)
	close_tween.tween_property(panel, "scale", Vector2(0.6, 0.6), 0.18)
	close_tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.15)
	await close_tween.finished

func start_speaking() -> void:
	var box: Control = text_dialog.get_parent()
	box.show()
	pop_in()
	get_parent().canmove = false
	var is_confirm: bool = PlayerTextDialog.current_state == PlayerTextDialog.DialogState.CONFIRMING
	while PlayerTextDialog.dialog_awaiting.size() > 0:
		var text_to_show: String = PlayerTextDialog.dialog_awaiting.pop_front()
		var is_last_line: bool = PlayerTextDialog.dialog_awaiting.size() == 0
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
		if is_confirm and is_last_line:
			await PlayerTextDialog.dialog_confirmed
		else:
			await dialogue_advanced
	get_parent().canmove = true
	await pop_out()
	box.hide()
	PlayerTextDialog.current_state = PlayerTextDialog.DialogState.WAITING
	PlayerTextDialog.dialog_closed.emit()

func answer_confirm(result: bool) -> void:
	PlayerTextDialog.dialog_confirmed.emit(result)
