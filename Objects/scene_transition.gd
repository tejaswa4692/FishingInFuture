extends CanvasLayer

##This script was made by AI along with the shader, i tweaked it to my likeing

@onready var water_rect: ColorRect = $WaterRect

var rise_duration: float = 0.7
var recede_duration: float = 0.6
var hold_duration: float = 0.05

var rise_trans: Tween.TransitionType = Tween.TRANS_SINE
var rise_ease: Tween.EaseType = Tween.EASE_IN
var recede_trans: Tween.TransitionType = Tween.TRANS_SINE
var recede_ease: Tween.EaseType = Tween.EASE_OUT


func _ready() -> void:
	layer = 100
	visible = false
	water_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_fill_level(0.0)


func change_scene(scene_path: String) -> void:
	visible = true
	await _play_rise()
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await _play_recede()
	visible = false

func change_scene_and_load(scene_path: String) -> void:
	visible = true
	await _play_rise()
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame #man js mind your own businees
	await get_tree().process_frame
	SaveGlobal.load_game()
	await _play_recede()
	visible = false

func _play_rise() -> void:
	var tween: Tween = create_tween()
	tween.tween_method(_set_fill_level, 0.0, 1.4, rise_duration).set_trans(rise_trans).set_ease(rise_ease)
	await tween.finished
	await get_tree().create_timer(hold_duration).timeout


func _play_recede() -> void:
	var tween: Tween = create_tween()
	tween.tween_method(_set_fill_level, 1.4, 0.0, recede_duration).set_trans(recede_trans).set_ease(recede_ease)
	await tween.finished


func _set_fill_level(value: float) -> void:
	var mat: ShaderMaterial = water_rect.material as ShaderMaterial
	mat.set_shader_parameter("fill_level", value)
