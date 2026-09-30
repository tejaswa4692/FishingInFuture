extends RigidBody3D

var water: WaterPhysics 
@onready var buoyancy_component: Node3D = $BuoyancyComponent
var player = null
var canControl: bool = false
@onready var mount_point: Marker3D = $MountPoint
var in_water: bool = false
@onready var save_script: Node = $save_script
@onready var ghost_player: Node3D = $Cube/ghostPlayer
var fuel_percentage = 100:
	set(value):
		fuel_percentage = value
		fuel_guage.material.set_shader_parameter("fV", value / 100.0)
@onready var fuel_guage: ColorRect = $BoatUI/ColorRect

func _ready() -> void:
	fuel_guage.hide()
	buoyancy_component.water = get_tree().get_first_node_in_group("water")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player = null

func hide_player() -> void:
	if player != null:
		player.hide()
		ghost_player.show()

func show_player() -> void:
	if player != null:
		player.show()
		ghost_player.hide()

func init_fuel_percentage() -> void:
	fuel_guage.material.set_shader_parameter("fV", fuel_percentage / 100.0)
