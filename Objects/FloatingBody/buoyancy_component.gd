extends Node3D
var water
@export var float_points: Array[Node3D] = []
@export var buoyancy_strength: float = 5.0
@export var point_damping: float = 2.0
@export var water_linear_damp: float = 0.3
@export var water_angular_damp: float = 0.3
@onready var body: RigidBody3D = get_parent()

const MAX_SUBMERSION: float = 1.0

func _physics_process(delta: float) -> void:
	if water == null or float_points.is_empty():
		return
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	var submerged_count: int = 0
	for point in float_points:
		var world_pos: Vector3 = point.global_position
		var wave_y: float = water.get_wave_world_y(Vector2(world_pos.x, world_pos.z), t)
		var submersion: float = clamp(wave_y - world_pos.y, 0.0, MAX_SUBMERSION)
		if submersion > 0.0:
			submerged_count += 1
			var offset: Vector3 = world_pos - body.global_position
			var point_velocity: Vector3 = body.linear_velocity + body.angular_velocity.cross(offset)
			var spring_force: float = submersion * buoyancy_strength
			var damp_force: float = -point_velocity.y * point_damping
			var force: Vector3 = Vector3.UP * (spring_force + damp_force)
			body.apply_force(force, offset)
	if submerged_count > 0:
		body.linear_velocity *= (1.0 - water_linear_damp * delta)
		body.angular_velocity *= (1.0 - water_angular_damp * delta)
