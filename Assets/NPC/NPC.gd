extends Node3D
@onready var anim_player = $NPCMesh/AnimationPlayer
var player
@export var dialogs: Array[String] = []
@onready var meshes: Array[MeshInstance3D] = [$NPCMesh/Armature/Skeleton3D/HandL_001, $NPCMesh/Armature/Skeleton3D/HandL_002, $NPCMesh/Armature/Skeleton3D/HandL_003, $NPCMesh/Armature/Skeleton3D/HandL_004]
const FRUITEGER_GLOSSY = preload("uid://lkod4xdl2a3t")

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_apply_random_material()
	if !self.is_in_group("idle_npc"):
		anim_player.play("Speak1")
	else:
		anim_player.play("Idle")

func _apply_random_material() -> void:
	# duplicate() creates a unique copy so mutating it never touches other NPCs
	var mat: ShaderMaterial = FRUITEGER_GLOSSY.duplicate()

	var hue := rng.randf()

	var base_col := Color.from_hsv(hue, rng.randf_range(0.4, 0.85), rng.randf_range(0.7, 1.0))
	base_col.a = rng.randf_range(0.4, 0.65)
	mat.set_shader_parameter("base_color", base_col)
	mat.set_shader_parameter("base_alpha", base_col.a)

	var rim_hue := fmod(hue + rng.randf_range(0.05, 0.2), 1.0)
	mat.set_shader_parameter("rim_color", Color.from_hsv(rim_hue, 0.2, 1.0))
	mat.set_shader_parameter("rim_power", rng.randf_range(1.5, 4.0))
	mat.set_shader_parameter("rim_strength", rng.randf_range(0.8, 2.0))

	var irid_a_hue := fmod(hue + 0.10, 1.0)
	var irid_b_hue := fmod(hue + 0.30, 1.0)
	mat.set_shader_parameter("iridescence_color_a", Color.from_hsv(irid_a_hue, 0.5, 1.0))
	mat.set_shader_parameter("iridescence_color_b", Color.from_hsv(irid_b_hue, 0.5, 1.0))
	mat.set_shader_parameter("iridescence_strength", rng.randf_range(0.1, 0.4))

	for m in meshes:
		m.material_override = mat

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_speak") and player != null:
		PlayerTextDialog.add_dialog(dialogs)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = null
