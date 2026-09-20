extends Node3D

@onready var camera: Camera3D = $CamPoints/Camera3D
@onready var campoint_array: Array[Marker3D] = [
	$CamPoints/CamPoint1,
	$CamPoints/CamPoint3,
	$CamPoints/CamPoint2
]

var current_point: int = 0


func _on_timer_timeout() -> void:
	current_point = (current_point + 1) % campoint_array.size()
	move_camera_to(campoint_array[current_point])


func move_camera_to(target: Marker3D) -> void: #Again this function has been written by AI cuz i hate writing tweens
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(
		camera,
		"global_position",
		target.global_position,
		2.5
	)
	tween.parallel().tween_property(
		camera,
		"global_rotation",
		target.global_rotation,
		2.5
	)


func _on_start_btn_pressed() -> void:
	SceneTransition.change_scene("res://Objects/World/world.tscn")


func _on_load_btn_pressed() -> void:
	SceneTransition.change_scene_and_load("res://Objects/World/world.tscn")


func _on_quit_btn_pressed() -> void:
	get_tree().quit()
