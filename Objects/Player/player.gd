extends CharacterBody3D
class_name Player

@onready var movement: MovementController = $MovementController
@onready var jump: JumpController = $JumpController
@onready var gravity_ctrl: GravityController = $GravityController
@onready var playermesh: Node3D = $Armature
@onready var bouey_script: Node = $BoueyScript
@onready var bouey_spawner: Marker3D = $Armature/FishingMarker/FishingRodMesh/Marker3D
@onready var animation_handler: Node = $AnimationHandler

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var item_list: ItemList = $MainUI/Inventory/Panel/ItemList
@onready var bubbles_counter: RichTextLabel = $MainUI/Bubbles
@onready var fishing_animation: AnimationPlayer = $FishingAnimation
@onready var player_hand_ik: CCDIK3D = $Armature/Skeleton3D/PlayerHandIK
@onready var fishing_rod_mesh: MeshInstance3D = $Armature/FishingMarker/FishingRodMesh
@onready var fish_caught_display: RichTextLabel = $MainUI/Fish_caught_display


var sellable_cost: int = 0

var mount_target = null
var casted: bool = false

var mounted: bool = false
var canmove: bool = true

@export var camera_ref: Node3D  

func _ready() -> void:
	inventory.player = self
	bubbles_counter.text = "Bubbles:" + "0"
	

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("cast"):
		if !casted:
			fishing_animation.play("Cast")
		else:
			fishing_animation.play("Retract")
	if Input.is_action_just_pressed("debug_show_sell"):
		print("showing")
		display_caught_text("hi", 0)

func _physics_process(delta: float) -> void:
	item_list.get_v_scroll_bar().hide()
	if mounted:
		return
	gravity_ctrl.apply_gravity(self, delta)
	if canmove:
		jump.update(self, delta)
		movement.update(self, delta, camera_ref)
	animation_handler.handleanim(delta)
	move_and_slide()
	movement.face_direction(self, playermesh, delta)

func mount(target: Node3D, mount_point: Node3D) -> void:
	mounted = true
	canmove = false
	mount_target = target
	velocity = Vector3.ZERO
	reparent(target)
	global_transform = mount_point.global_transform


func unmount() -> void:
	var world := get_tree().current_scene
	reparent(world)
	rotation_degrees = Vector3(0, 0, 0)
	mounted = false
	canmove = true
	mount_target = null


func display_caught_text(fish_name: String, weight: float) -> void:
	fish_caught_display.show()
	fish_caught_display.text = "caught " + fish_name + "weighing at " + str(int(weight))
	var tween = create_tween()
	tween.tween_property(fish_caught_display, "modulate:a", 1, 0.5)
	tween.tween_interval(0.5)
	tween.tween_property(fish_caught_display, "modulate:a", 0, 0.5)
	pass

func display_sold(sell_price: int) -> void:
	fish_caught_display.show()
	fish_caught_display.text = "sold all fishes for: " + str(sell_price)
	var tween = create_tween()
	tween.tween_property(fish_caught_display, "modulate:a", 1, 0.5)
	tween.tween_interval(0.5)
	tween.tween_property(fish_caught_display, "modulate:a", 0, 0.5)
	pass
