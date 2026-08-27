extends CharacterBody3D
class_name Player

@onready var movement: MovementController = $MovementController
@onready var jump: JumpController = $JumpController
@onready var gravity_ctrl: GravityController = $GravityController
@onready var playermesh: Node3D = $Armature
@onready var bouey_script: Node = $BoueyScript
@onready var bouey_spawner: Marker3D = $Armature/Marker3D
@onready var animation_handler: Node = $AnimationHandler

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var item_list: ItemList = $MainUI/Inventory/Panel/ItemList

var mount_target = null
var casted: bool = false

var mounted: bool = false
var canmove: bool = true

@export var camera_ref: Node3D  


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("cast"):
		if !casted:
			bouey_script.spawn_booey()
			casted = true
		else:
			bouey_script.reel_back_in()

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
