extends Node

enum DialogState { WAITING, SPEAKING }

var current_state: DialogState = DialogState.WAITING
var player: Player
var dialog_awaiting: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_speak"):
		
		if current_state == DialogState.SPEAKING:
			player.player_dialog_controller.dialogue_advanced.emit()


func add_dialog(dialog: Array[String]) -> void:
	dialog_awaiting.append_array(dialog)
	if current_state == DialogState.SPEAKING:
		return
	current_state = DialogState.SPEAKING
	player.player_dialog_controller.start_speaking()
