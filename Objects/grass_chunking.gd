class_name PlanetGrassScatterer
extends Node3D

@export var grass_mesh: Mesh
@export var grass_shader: Shader
@export var blades_per_chunk := 5000
@export var auto_generate_on_ready: bool = false

## Base tint, same pattern as the rock scatterer -- set externally by
## GravitySource with the planet's color_low before regenerate().
@export var base_grass_color: Color = Color(0.35, 0.55, 0.25)
@export var hue_jitter := 0.04
@export var saturation_jitter := 0.15
@export var value_jitter := 0.2

const PLANET_RADIUS := 20.0
const GRASS_RENDER_DISTANCE := 120.0
const MIN_DISTANCE := 0.15   # much denser than rocks
const CELL_SIZE := MIN_DISTANCE

var chunks: Dictionary = {}
var _grass_material: ShaderMaterial

var _generation_thread: Thread = null
var _is_generating := false

class Chunk:
	var center: Vector3
	var node := Node3D.new()
	var multimesh := MultiMesh.new()
	var multimesh_instance := MultiMeshInstance3D.new()
	var transforms: Array = []
	var colors: Array = []
	var custom_datas: Array = []


func _ready() -> void:
	_grass_material = ShaderMaterial.new()
	_grass_material.shader = grass_shader

	create_chunks()
	if auto_generate_on_ready:
		start_generation()


func _exit_tree() -> void:
	if _generation_thread != null:
		_generation_thread.wait_to_finish()
		_generation_thread = null


var _visibility_timer := 0.0
func _process(delta: float) -> void:
	_visibility_timer += delta
	if _visibility_timer >= 0.1:
		_visibility_timer = 0.0
		update_chunk_visibility(get_viewport().get_camera_3d())


func set_base_color(color: Color) -> void:
	base_grass_color = color


func create_chunks() -> void:
	chunks.clear()
	for x in [-1, 0, 1]:
		for y in [-1, 0, 1]:
			for z in [-1, 0, 1]:
				if x == 0 and y == 0 and z == 0:
					continue
				var chunk := Chunk.new()
				chunk.center = Vector3(x, y, z) * PLANET_RADIUS
				chunk.node.name = "GrassChunk_%d_%d_%d" % [x, y, z]

				chunk.multimesh.mesh = grass_mesh
				chunk.multimesh.transform_format = MultiMesh.TRANSFORM_3D
				chunk.multimesh.use_colors = true
				chunk.multimesh.use_custom_data = true
				chunk.multimesh_instance.multimesh = chunk.multimesh
				chunk.multimesh_instance.material_override = _grass_material
				chunk.node.add_child(chunk.multimesh_instance)

				add_child(chunk.node)
				chunks[Vector3i(x, y, z)] = chunk


func regenerate() -> void:
	if _is_generating:
		push_warning("PlanetGrassScatterer: generation already in progress, ignoring regenerate() call")
		return
	start_generation()


func is_generating() -> bool:
	return _is_generating


func start_generation() -> void:
	if _is_generating:
		return
	_is_generating = true

	var sphere: MeshInstance3D = get_parent().get_node("SourceMesh")
	var arrays = sphere.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var sphere_transform: Transform3D = sphere.global_transform
	var to_local_transform: Transform3D = self.global_transform.affine_inverse()

	_generation_thread = Thread.new()
	_generation_thread.start(
		_generate_grass_threaded.bind(
			vertices, indices, sphere_transform, to_local_transform,
			blades_per_chunk,
			base_grass_color, hue_jitter, saturation_jitter, value_jitter
		)
	)


## BACKGROUND THREAD. No Node/resource access -- plain data in, plain data out.
func _generate_grass_threaded(
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	sphere_transform: Transform3D,
	to_local_transform: Transform3D,
	target_per_chunk: int,
	color_base: Color,
	h_jitter: float,
	s_jitter: float,
	v_jitter: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var grid := {}
	var result: Dictionary = {}
	var chunk_counts: Dictionary = {}
	for cx in [-1, 0, 1]:
		for cy in [-1, 0, 1]:
			for cz in [-1, 0, 1]:
				if cx == 0 and cy == 0 and cz == 0:
					continue
				var key := Vector3i(cx, cy, cz)
				result[key] = {"transforms": [], "colors": [], "custom": []}
				chunk_counts[key] = 0

	var total_target: int = target_per_chunk * chunk_counts.size()
	var placed := 0
	var attempts := 0
	var max_attempts := total_target * 15  # grass needs more attempts than rocks, packing is tighter

	while placed < total_target and attempts < max_attempts:
		attempts += 1

		var tri = (rng.randi() % (indices.size() / 3)) * 3
		var a = vertices[indices[tri]]
		var b = vertices[indices[tri + 1]]
		var c = vertices[indices[tri + 2]]

		var r1 = sqrt(rng.randf())
		var r2 = rng.randf()
		var pos = (1.0 - r1) * a + r1 * (1.0 - r2) * b + r1 * r2 * c
		var normal = pos.normalized()
		var world_pos = sphere_transform * pos

		var chunk_key = Vector3i(
			1 if normal.x > 0.33 else (-1 if normal.x < -0.33 else 0),
			1 if normal.y > 0.33 else (-1 if normal.y < -0.33 else 0),
			1 if normal.z > 0.33 else (-1 if normal.z < -0.33 else 0)
		)
		if chunk_key == Vector3i.ZERO:
			continue

		# skip if that chunk already has its 5000
		if chunk_counts[chunk_key] >= target_per_chunk:
			continue

		var cell = Vector3i(
			floor(world_pos.x / CELL_SIZE),
			floor(world_pos.y / CELL_SIZE),
			floor(world_pos.z / CELL_SIZE)
		)

		var valid := true
		for x in range(cell.x - 1, cell.x + 2):
			for y in range(cell.y - 1, cell.y + 2):
				for z in range(cell.z - 1, cell.z + 2):
					var neighbor_key = Vector3i(x, y, z)
					if !grid.has(neighbor_key):
						continue
					for other in grid[neighbor_key]:
						if world_pos.distance_to(other) < MIN_DISTANCE:
							valid = false
							break
					if !valid:
						break
				if !valid:
					break
			if !valid:
				break
		if !valid:
			continue

		if !grid.has(cell):
			grid[cell] = []
		grid[cell].append(world_pos)

		var up = normal
		var forward = Vector3.FORWARD
		if abs(up.dot(forward)) > 0.99:
			forward = Vector3.RIGHT
		var right = forward.cross(up).normalized()
		forward = up.cross(right).normalized()

		var basis = Basis(right, up, -forward)
		basis = basis.rotated(up, rng.randf() * TAU)  # random yaw, blades still stand upright on surface

		var scale = rng.randf_range(0.7, 1.3)
		basis = basis.scaled(Vector3.ONE * scale)

		var transform = Transform3D(basis, world_pos)
		transform = to_local_transform * transform

		var grass_color := Color.from_hsv(
			fmod(color_base.h + rng.randf_range(-h_jitter, h_jitter) + 1.0, 1.0),
			clamp(color_base.s + rng.randf_range(-s_jitter, s_jitter), 0.0, 1.0),
			clamp(color_base.v + rng.randf_range(-v_jitter, v_jitter), 0.05, 1.0)
		)

		# .x = wind phase offset, .y = per-blade displacement strength,
		# read as INSTANCE_CUSTOM in your grass shader
		var custom := Color(rng.randf(), rng.randf_range(0.6, 1.0), 0.0, 0.0)

		result[chunk_key]["transforms"].append(transform)
		result[chunk_key]["colors"].append(grass_color)
		result[chunk_key]["custom"].append(custom)
		chunk_counts[chunk_key] += 1
		placed += 1

	call_deferred("_on_generation_complete", result)


func _on_generation_complete(result: Dictionary) -> void:
	for chunk_key in result:
		if !chunks.has(chunk_key):
			continue
		var chunk: Chunk = chunks[chunk_key]
		chunk.transforms = result[chunk_key]["transforms"]
		chunk.colors = result[chunk_key]["colors"]
		chunk.custom_datas = result[chunk_key]["custom"]
	build_multimeshes()
	if _generation_thread != null:
		_generation_thread.wait_to_finish()
		_generation_thread = null
	_is_generating = false


func build_multimeshes() -> void:
	for chunk in chunks.values():
		var mm: MultiMesh = chunk.multimesh
		mm.instance_count = chunk.transforms.size()
		for i in range(chunk.transforms.size()):
			mm.set_instance_transform(i, chunk.transforms[i])
			mm.set_instance_color(i, chunk.colors[i])
			mm.set_instance_custom_data(i, chunk.custom_datas[i])


func update_chunk_visibility(camera: Camera3D) -> void:
	var planet_pos = get_parent().global_position
	var distance = camera.global_position.distance_to(planet_pos)

	if distance > GRASS_RENDER_DISTANCE:
		for chunk in chunks.values():
			chunk.node.visible = false
		return

	var cam_dir = (camera.global_position - planet_pos).normalized()
	for chunk in chunks.values():
		var chunk_dir = chunk.center.normalized()
		chunk.node.visible = chunk_dir.dot(cam_dir) > 0.2
