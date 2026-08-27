extends Control

@export var items: Array[Texture2D] = []
@export var radius: float = 150.0
@export var rotation_offset: float = -90.0

var selected_index: int = 0
var buttons: Array[TextureButton] = []


func _ready() -> void:
	for child in get_children():
		if child is TextureButton:
			buttons.append(child)

	update_inventory()


func update_inventory() -> void:
	if items.is_empty():
		return

	var center := size / 2.0
	var count := buttons.size()

	for i in count:
		var item_index := posmod(selected_index + i, items.size())
		var button := buttons[i]

		button.texture_normal = items[item_index]

		var angle := deg_to_rad(rotation_offset + (360.0 / count) * i)

		var position := center + Vector2(
			cos(angle),
			sin(angle)
		) * radius

		button.position = position - button.size / 2.0


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			selected_index = posmod(selected_index - 1, items.size())
			update_inventory()
			accept_event()

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			selected_index = posmod(selected_index + 1, items.size())
			update_inventory()
			accept_event()
