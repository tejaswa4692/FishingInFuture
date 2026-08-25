# WaterPhysics.gd
class_name WaterPhysics
extends Node3D

@export var wave_height: float = 0.15
@export var wave_speed: float = 0.8
@export var wave_scale: float = 1.0
@export var wave_count: int = 4

func wave_height_at(pos: Vector2, t: float) -> float:
	var h: float = 0.0
	var amp: float = 1.0
	var freq: float = wave_scale
	for i in range(wave_count):
		var dir: Vector2 = Vector2(sin(float(i) * 12.9898), cos(float(i) * 78.233)).normalized()
		h += sin(pos.dot(dir) * freq + t * wave_speed) * amp
		amp *= 0.55
		freq *= 1.8
	return h * wave_height

func get_wave_world_y(world_xz: Vector2, t: float) -> float:
	return global_position.y + wave_height_at(world_xz, t)
