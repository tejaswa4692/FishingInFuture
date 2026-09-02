extends Node3D
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@export var daynightcyclespeed := 1.0
@export var max_energy := 1.0
@export var min_energy := 0.0
@export var twilight_range := 15.0
@onready var area_light_3d: AreaLight3D = $AreaLight3D

func _process(delta: float) -> void:
	sun.rotation_degrees.x = fposmod(
		sun.rotation_degrees.x + daynightcyclespeed * delta,
		360.0
	)

	if sun.rotation_degrees.x < 180.0:
		Almighty.current_time = Almighty.TimeOfDay.NIGHT
		area_light_3d.show()
	else:
		Almighty.current_time = Almighty.TimeOfDay.MORNING
		area_light_3d.hide()

	_update_sun_energy()

func _update_sun_energy() -> void:
	var angle := sun.rotation_degrees.x
	var t: float

	if angle < 180.0:
		var dist_from_night_start := angle - 180.0
		var dist_from_night_end := 360.0 - angle
		t = clamp(min(dist_from_night_start, dist_from_night_end) / twilight_range, 0.0, 1.0)
	else:
		t = 1.0

	sun.light_energy = lerp(min_energy, max_energy, t)
