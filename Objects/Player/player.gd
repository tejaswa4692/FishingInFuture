extends CharacterBody3D
class_name Player

@onready var movement: MovementController = $MovementController
@onready var jump: JumpController = $JumpController
@onready var gravity_ctrl: GravityController = $GravityController
@onready var playermesh: Node3D = $Player


@export var camera_ref: Node3D  # assign your MousePivot (or the camera itself) in the Inspector

func _physics_process(delta: float) -> void:
	gravity_ctrl.apply_gravity(self, delta)
	jump.update(self, delta)
	movement.update(self, delta, camera_ref)
	move_and_slide()
	movement.face_direction(self, playermesh, delta)
