extends Node

@export var resolution_divisor: float = 1.5


func _ready() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_tree().root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL

	get_tree().root.size_changed.connect(_on_window_resized)
	_on_window_resized()

func _on_window_resized() -> void:
	var window_size := DisplayServer.window_get_size()
	var target_size := Vector2i(
		max(1, int(window_size.x / resolution_divisor)),
		max(1, int(window_size.y / resolution_divisor))
	)
	get_tree().root.content_scale_size = target_size
