# BuoyancyComponent.gd
extends Node3D

@export var water: WaterPhysics
@export var float_points: Array[Node3D] = []
@export var buoyancy_strength: float = 15.0
@export var water_linear_damp: float = 0.6
@export var water_angular_damp: float = 0.8

@onready var body: RigidBody3D = get_parent()

func _physics_process(delta: float) -> void:
	if water == null or float_points.is_empty():
		return

	var t: float = float(Time.get_ticks_msec()) / 1000.0
	var submerged_count: int = 0

	for point in float_points:
		var world_pos: Vector3 = point.global_position
		var wave_y: float = water.get_wave_world_y(Vector2(world_pos.x, world_pos.z), t)
		var submersion: float = wave_y - world_pos.y

		if submersion > 0.0:
			submerged_count += 1
			var force: Vector3 = Vector3.UP * submersion * buoyancy_strength
			body.apply_force(force, world_pos - body.global_position)

	if submerged_count > 0:
		body.linear_velocity *= (1.0 - water_linear_damp * delta)
		body.angular_velocity *= (1.0 - water_angular_damp * delta)
