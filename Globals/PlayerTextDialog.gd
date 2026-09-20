extends Node
enum DialogState { WAITING, SPEAKING, CONFIRMING }
var current_state: DialogState = DialogState.WAITING
var player: Player
var dialog_awaiting: Array[String] = []
signal dialog_confirmed(result: bool)
signal dialog_closed

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_speak"):
		if current_state == DialogState.SPEAKING:
			player.player_dialog_controller.dialogue_advanced.emit()
	if current_state == DialogState.CONFIRMING:
		if _event is InputEventKey and _event.pressed and not _event.echo:
			if _event.keycode == KEY_Y:
				player.player_dialog_controller.answer_confirm(true)
			elif _event.keycode == KEY_N:
				player.player_dialog_controller.answer_confirm(false)

func add_dialog(dialog: Array[String]) -> void:
	if current_state == DialogState.SPEAKING or current_state == DialogState.CONFIRMING:
		return
	dialog_awaiting.append_array(dialog)
	current_state = DialogState.SPEAKING
	player.player_dialog_controller.start_speaking()

func ask_yes_no(prompt: Array[String]) -> bool:
	if current_state != DialogState.WAITING:
		return false
	dialog_awaiting.append_array(prompt)
	current_state = DialogState.CONFIRMING
	player.player_dialog_controller.start_speaking()
	var result: bool = await dialog_confirmed
	await dialog_closed
	return result
