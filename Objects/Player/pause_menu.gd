extends Control

@onready var player_info: RichTextLabel = $PlayerInfo
@onready var last_save: RichTextLabel = $LastSave
@onready var player = get_parent()
var menu_tween: Tween

func _ready() -> void:
	pivot_offset = size/2

func animate_menu(showing: bool) -> void: #this function is AI generated, this is js tedious for sone reason in godot
	if menu_tween:
		menu_tween.kill()
	if showing:
		show()
		scale = Vector2(0.85, 0.85)
		modulate.a = 0.0
		menu_tween = create_tween().set_parallel(true)
		menu_tween.tween_property(self, "scale", Vector2.ONE, 0.2)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
		menu_tween.tween_property(self, "modulate:a", 1.0, 0.15)
	else:
		menu_tween = create_tween().set_parallel(true)
		menu_tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.15)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_IN)
		menu_tween.tween_property(self, "modulate:a", 0.0, 0.1)
		menu_tween.chain().tween_callback(hide)


func show_menu() -> void: #The formatting for the inventory in this function is AI generated again its easy but tedious
	show()
	update()
	player.ui_open = true

func update() -> void:
	if SaveGlobal.last_timestamp != "":
		last_save.text = "Last game saved on: " + SaveGlobal.last_timestamp
	else:
		last_save.text = "No game saved yet (or if you have then this might js be a bug TuT)"
	var info := ""
	info += "Dabloons: " + str(inventory.playerTotalHoldingCost) + "\n\n"
	info += "Inventory\n"
	info += "──────────────────\n"
	for fish in inventory.playerInventory:
		info += fish["display_name"] + "\n"
		info += "  Price: " + str(fish["price"]) + " Dabloons\n"
		info += "  Rarity: " + fish["rarity"].capitalize() + "\n"
		info += "  Weight: " + str(fish["weight"]) + " kg\n\n"
	player_info.text = info

func hide_menu() -> void:
	hide()
	player.ui_open = false

func show_hide_handler() -> void:
	if visible:
		animate_menu(false)
		player.ui_open = false
	else:
		show_menu()
		animate_menu(true)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_action_just_pressed("ui_cancel"):
			show_hide_handler()

func save_btn_pressed() -> void:
	SaveGlobal.save()
	update()

func load_btn_pressed() -> void:
	SaveGlobal.load_game()
	update()

func quit_btn_pressed() -> void:
	SceneTransition.change_scene("res://Objects/World/main_menu.tscn")
