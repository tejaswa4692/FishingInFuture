extends Node3D

@export var grass_mesh: Mesh
@export var grass_material: Material
@export var blade_scale: float = 1.0

@export var ground_mesh_instance: MeshInstance3D
@export var player: Node3D

@export var chunk_size: float = 8.0
@export var view_radius_chunks: int = 6
@export var near_blade_count: int = 5000
@export var far_blade_count: int = 300
@export var lod_falloff_chunks: float = 4.0
@export var blade_min_distance: float = 0.15
@export var update_interval: float = 0.25
@export var density_step: int = 500  ## regen only triggers when target crosses a step this size
@export var grass_seed: int = 12345  ## same seed used for every chunk's RNG, so generation is deterministic/reproducible

var _triangle_buckets: Dictionary = {}
var _buckets_ready: bool = false

var chunks: Dictionary = {}
var _pending_keys: Dictionary = {}
var _threads: Dictionary = {}
var _update_timer: float = 0.0

class Chunk:
	var node: Node3D = Node3D.new()
	var multimesh: MultiMesh = MultiMesh.new()
	var multimesh_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	var current_target: int = 0  ## last blade_count this chunk was generated/requested at


func _ready() -> void:
	if grass_mesh == null:
		push_error("GrassChunking: grass_mesh not assigned in Inspector")
		return
	if grass_material == null:
		push_error("GrassChunking: grass_material not assigned in Inspector")
		return
	if ground_mesh_instance == null or ground_mesh_instance.mesh == null:
		push_error("GrassChunking: ground_mesh_instance not set or has no Mesh assigned")
		return
	if player == null:
		push_error("GrassChunking: player not set")
		return

	_build_triangle_buckets()


func _exit_tree() -> void:
	for key: Vector2i in _threads.keys():
		_threads[key].wait_to_finish()
	_threads.clear()


func _process(delta: float) -> void:
	if not _buckets_ready:
		return
	_update_timer += delta
	if _update_timer < update_interval:
		return
	_update_timer = 0.0
	_update_chunks()


func _build_triangle_buckets() -> void:
	var arrays: Array = ground_mesh_instance.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var ground_transform: Transform3D = ground_mesh_instance.global_transform

	_triangle_buckets.clear()

	var tri_count: int = indices.size() / 3
	for t: int in range(tri_count):
		var a: Vector3 = ground_transform * vertices[indices[t * 3]]
		var b: Vector3 = ground_transform * vertices[indices[t * 3 + 1]]
		var c: Vector3 = ground_transform * vertices[indices[t * 3 + 2]]

		var centroid: Vector3 = (a + b + c) / 3.0
		var key: Vector2i = Vector2i(floori(centroid.x / chunk_size), floori(centroid.z / chunk_size))

		if not _triangle_buckets.has(key):
			_triangle_buckets[key] = []
		_triangle_buckets[key].append([a, b, c])

	_buckets_ready = true
	print("GrassChunking: bucketed ", tri_count, " triangles into ", _triangle_buckets.size(), " chunks")


func _update_chunks() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return

	var player_chunk: Vector2i = Vector2i(
		floori(player.global_position.x / chunk_size),
		floori(player.global_position.z / chunk_size)
	)

	var needed: Dictionary = {}
	for dx: int in range(-view_radius_chunks, view_radius_chunks + 1):
		for dz: int in range(-view_radius_chunks, view_radius_chunks + 1):
			var dist_chunks: float = Vector2(dx, dz).length()
			if dist_chunks > view_radius_chunks:
				continue

			var key: Vector2i = Vector2i(player_chunk.x + dx, player_chunk.y + dz)
			if not _triangle_buckets.has(key):
				continue

			needed[key] = true

			var desired_count: int = _quantized_blade_count_for_distance(dist_chunks)

			if chunks.has(key):
				# already spawned -- check whether density needs updating
				var chunk: Chunk = chunks[key]
				if desired_count != chunk.current_target and not _pending_keys.has(key):
					_regenerate_chunk(key, desired_count)
				continue

			if _pending_keys.has(key):
				continue

			var chunk_center: Vector3 = Vector3(
				(key.x + 0.5) * chunk_size,
				player.global_position.y,
				(key.y + 0.5) * chunk_size
			)

			if not camera.is_position_in_frustum(chunk_center):
				continue

			_spawn_chunk(key, desired_count)

	for key: Vector2i in chunks.keys():
		if not needed.has(key):
			_despawn_chunk(key)


func _blade_count_for_distance(dist_chunks: float) -> int:
	var t: float = clamp(dist_chunks / lod_falloff_chunks, 0.0, 1.0)
	return int(lerp(float(near_blade_count), float(far_blade_count), t))


## Rounds the raw distance-based count to the nearest density_step, so
## chunks don't regenerate every single tick as the player drifts a few
## units -- only when they cross a real LOD band.
func _quantized_blade_count_for_distance(dist_chunks: float) -> int:
	var raw: int = _blade_count_for_distance(dist_chunks)
	if density_step <= 0:
		return raw
	return int(round(float(raw) / float(density_step))) * density_step


func _spawn_chunk(key: Vector2i, blade_count: int) -> void:
	if blade_count <= 0:
		return
	_pending_keys[key] = true

	var chunk: Chunk = Chunk.new()
	chunk.node.name = "GrassChunk_%d_%d" % [key.x, key.y]
	chunk.multimesh.mesh = grass_mesh
	chunk.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	chunk.multimesh.use_colors = true
	chunk.multimesh.use_custom_data = true
	chunk.multimesh_instance.multimesh = chunk.multimesh
	chunk.multimesh_instance.material_override = grass_material
	chunk.multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	chunk.node.add_child(chunk.multimesh_instance)
	add_child(chunk.node)

	chunk.current_target = blade_count
	chunks[key] = chunk

	_launch_generation(key, blade_count)


## Regenerates an EXISTING chunk's blade set in place (same node, same
## MultiMesh resource) rather than despawning/respawning, so there's no
## visible pop when density changes as the player moves.
func _regenerate_chunk(key: Vector2i, blade_count: int) -> void:
	if blade_count <= 0:
		_despawn_chunk(key)
		return
	var chunk: Chunk = chunks[key]
	chunk.current_target = blade_count
	_pending_keys[key] = true
	_launch_generation(key, blade_count)


func _launch_generation(key: Vector2i, blade_count: int) -> void:
	var triangles: Array = _triangle_buckets[key]
	var to_local_transform: Transform3D = self.global_transform.affine_inverse()

	var thread: Thread = Thread.new()
	_threads[key] = thread
	thread.start(_generate_chunk_threaded.bind(key, triangles, to_local_transform, blade_count, blade_min_distance, blade_scale, grass_seed))


func _despawn_chunk(key: Vector2i) -> void:
	if chunks.has(key):
		chunks[key].node.queue_free()
		chunks.erase(key)


func _generate_chunk_threaded(
	key: Vector2i,
	triangles: Array,
	to_local_transform: Transform3D,
	blade_count: int,
	min_dist: float,
	base_scale: float,
	rng_seed: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = rng_seed

	var grid: Dictionary = {}
	var transforms: Array = []
	var customs: Array = []

	var tri_count: int = triangles.size()
	if tri_count == 0:
		call_deferred("_on_chunk_generated", key, transforms, customs)
		return

	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = blade_count * 20

	while placed < blade_count and attempts < max_attempts:
		attempts += 1

		var tri: Array = triangles[rng.randi() % tri_count]
		var a: Vector3 = tri[0]
		var b: Vector3 = tri[1]
		var c: Vector3 = tri[2]

		var r1: float = sqrt(rng.randf())
		var r2: float = rng.randf()
		var world_pos: Vector3 = (1.0 - r1) * a + r1 * (1.0 - r2) * b + r1 * r2 * c

		var cell: Vector3i = Vector3i(
			floori(world_pos.x / min_dist),
			floori(world_pos.y / min_dist),
			floori(world_pos.z / min_dist)
		)

		var valid: bool = true
		for x: int in range(cell.x - 1, cell.x + 2):
			for y: int in range(cell.y - 1, cell.y + 2):
				for z: int in range(cell.z - 1, cell.z + 2):
					var nk: Vector3i = Vector3i(x, y, z)
					if not grid.has(nk):
						continue
					for other: Vector3 in grid[nk]:
						if world_pos.distance_to(other) < min_dist:
							valid = false
							break
					if not valid:
						break
				if not valid:
					break
			if not valid:
				break
		if not valid:
			continue

		if not grid.has(cell):
			grid[cell] = []
		grid[cell].append(world_pos)

		var normal: Vector3 = (b - a).cross(c - a).normalized()
		if normal.dot(Vector3.UP) < 0.0:
			normal = -normal
		var forward: Vector3 = Vector3.FORWARD
		if abs(normal.dot(forward)) > 0.99:
			forward = Vector3.RIGHT
		var right: Vector3 = forward.cross(normal).normalized()
		forward = normal.cross(right).normalized()

		var basis: Basis = Basis(right, normal, -forward)
		basis = basis.rotated(normal, rng.randf() * TAU)
		var scale: float = rng.randf_range(0.85, 1.15) * base_scale
		basis = basis.scaled(Vector3.ONE * scale)

		var transform: Transform3D = to_local_transform * Transform3D(basis, world_pos)
		var custom: Color = Color(rng.randf(), rng.randf_range(0.6, 1.0), 0.0, 0.0)

		transforms.append(transform)
		customs.append(custom)
		placed += 1

	call_deferred("_on_chunk_generated", key, transforms, customs)


func _on_chunk_generated(key: Vector2i, transforms: Array, customs: Array) -> void:
	_pending_keys.erase(key)
	if _threads.has(key):
		_threads[key].wait_to_finish()
		_threads.erase(key)

	if not chunks.has(key):
		return

	var chunk: Chunk = chunks[key]
	var mm: MultiMesh = chunk.multimesh
	mm.instance_count = transforms.size()
	for i: int in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, Color.WHITE)
		mm.set_instance_custom_data(i, customs[i])
