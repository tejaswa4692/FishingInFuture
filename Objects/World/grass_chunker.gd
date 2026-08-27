extends Node3D

@export var grass_mesh: Mesh
@export var grass_material: Material
@export var blade_scale: float = 1.0

@export var ground_mesh_instance: MeshInstance3D
@export var player: Node3D

@export var chunk_size: float = 8.0
@export var view_radius_chunks: int = 6
@export var near_blade_count: int = 5000   ## also the count every chunk is generated at (max)
@export var far_blade_count: int = 300
@export var lod_falloff_chunks: float = 4.0
@export var blade_min_distance: float = 0.15
@export var update_interval: float = 0.25  ## how often spawn/despawn membership is re-checked
@export var grass_seed: int = 12345

var _triangle_buckets: Dictionary = {}
var _buckets_ready: bool = false

var chunks: Dictionary = {}          # Vector2i -> Chunk (spawned, fully or partially generated)
var _pending_keys: Dictionary = {}   # keys currently generating on WorkerThreadPool
var _task_id_to_key: Dictionary = {}
var _task_results: Dictionary = {}
var _pending_task_ids: Array = []
var _update_timer: float = 0.0

class Chunk:
	var node: Node3D = Node3D.new()
	var multimesh: MultiMesh = MultiMesh.new()
	var multimesh_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	var center: Vector3 = Vector3.ZERO


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


func _process(delta: float) -> void:
	if not _buckets_ready:
		return
	
	# poll any WorkerThreadPool generation tasks that finished this frame
	if _pending_task_ids.size() > 0:
		var still_pending: Array = []
		for task_id: int in _pending_task_ids:
			if WorkerThreadPool.is_task_completed(task_id):
				WorkerThreadPool.wait_for_task_completion(task_id)
				var key: Vector2i = _task_id_to_key[task_id]
				var data: Dictionary = _task_results[task_id]
				_finish_chunk_build(key, data)
				_task_id_to_key.erase(task_id)
				_task_results.erase(task_id)
				_pending_keys.erase(key)
			else:
				still_pending.append(task_id)
		_pending_task_ids = still_pending

	# cheap per-frame work: continuous LOD via visible_instance_count, no regeneration
	_update_visible_counts()

	_update_timer += delta
	if _update_timer < update_interval:
		return
	_update_timer = 0.0
	_update_chunk_membership()


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


## Distance-based target blade count, continuous (no step quantization) --
## this is what makes the transition smooth, since it's evaluated every
## frame and applied directly via visible_instance_count.
func _blade_count_for_distance(dist_chunks: float) -> int:
	var t: float = clamp(dist_chunks / lod_falloff_chunks, 0.0, 1.0)
	return int(round(lerp(float(near_blade_count), float(far_blade_count), t)))


## Cheap: no threads, no regeneration -- just tells the GPU how many of the
## already-generated instances to draw this frame.
func _update_visible_counts() -> void:
	for key: Vector2i in chunks.keys():
		var chunk: Chunk = chunks[key]
		var dist_chunks: float = Vector2(chunk.center.x, chunk.center.z).distance_to(
			Vector2(player.global_position.x, player.global_position.z)
		) / chunk_size
		var target: int = _blade_count_for_distance(dist_chunks)
		chunk.multimesh.visible_instance_count = clampi(target, 0, chunk.multimesh.instance_count)


func _update_chunk_membership() -> void:
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
			if Vector2(dx, dz).length() > view_radius_chunks:
				continue

			var key: Vector2i = Vector2i(player_chunk.x + dx, player_chunk.y + dz)
			if not _triangle_buckets.has(key):
				continue

			needed[key] = true

			if chunks.has(key) or _pending_keys.has(key):
				continue

			var chunk_center: Vector3 = Vector3(
				(key.x + 0.5) * chunk_size,
				player.global_position.y,
				(key.y + 0.5) * chunk_size
			)
			if not camera.is_position_in_frustum(chunk_center):
				continue

			_spawn_chunk(key)

	for key: Vector2i in chunks.keys():
		if not needed.has(key):
			_despawn_chunk(key)


## Chunk is generated ONCE, always at near_blade_count (the max), regardless
## of current distance -- density from here on is purely visible_instance_count.
func _spawn_chunk(key: Vector2i) -> void:
	_pending_keys[key] = true

	var triangles: Array = _triangle_buckets[key]
	var to_local_transform: Transform3D = self.global_transform.affine_inverse()

	var task_id: int = WorkerThreadPool.add_task(
		_generate_chunk_task.bind(key, triangles, to_local_transform)
	)
	_task_id_to_key[task_id] = key
	_pending_task_ids.append(task_id)


func _despawn_chunk(key: Vector2i) -> void:
	if chunks.has(key):
		chunks[key].node.queue_free()
		chunks.erase(key)


## Runs on a WorkerThreadPool worker thread. No Node/Resource access --
## plain data in via bind, plain data written to _task_results, picked up
## by _process() once WorkerThreadPool.is_task_completed() is true.
func _generate_chunk_task(key: Vector2i, triangles: Array, to_local_transform: Transform3D) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = grass_seed + int(key.x) * 73856093 ^ int(key.y) * 19349663

	var grid: Dictionary = {}
	var transforms: Array = []
	var customs: Array = []
	var sum_pos: Vector3 = Vector3.ZERO

	var tri_count: int = triangles.size()
	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = near_blade_count * 20

	while placed < near_blade_count and attempts < max_attempts and tri_count > 0:
		attempts += 1

		var tri: Array = triangles[rng.randi() % tri_count]
		var a: Vector3 = tri[0]
		var b: Vector3 = tri[1]
		var c: Vector3 = tri[2]

		var r1: float = sqrt(rng.randf())
		var r2: float = rng.randf()
		var world_pos: Vector3 = (1.0 - r1) * a + r1 * (1.0 - r2) * b + r1 * r2 * c

		var cell: Vector3i = Vector3i(
			floori(world_pos.x / blade_min_distance),
			floori(world_pos.y / blade_min_distance),
			floori(world_pos.z / blade_min_distance)
		)

		var valid: bool = true
		for x: int in range(cell.x - 1, cell.x + 2):
			for y: int in range(cell.y - 1, cell.y + 2):
				for z: int in range(cell.z - 1, cell.z + 2):
					var nk: Vector3i = Vector3i(x, y, z)
					if not grid.has(nk):
						continue
					for other: Vector3 in grid[nk]:
						if world_pos.distance_to(other) < blade_min_distance:
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
		var scale: float = rng.randf_range(0.85, 1.15) * blade_scale
		basis = basis.scaled(Vector3.ONE * scale)

		var transform: Transform3D = to_local_transform * Transform3D(basis, world_pos)
		var custom: Color = Color(rng.randf(), rng.randf_range(0.6, 1.0), 0.0, 0.0)

		transforms.append(transform)
		customs.append(custom)
		sum_pos += world_pos
		placed += 1

	var center: Vector3 = sum_pos / float(placed) if placed > 0 else Vector3.ZERO
	_task_results[_task_id_for(key)] = {"center": center, "transforms": transforms, "customs": customs}


func _task_id_for(key: Vector2i) -> int:
	for task_id: int in _task_id_to_key.keys():
		if _task_id_to_key[task_id] == key:
			return task_id
	return -1


func _finish_chunk_build(key: Vector2i, data: Dictionary) -> void:
	var transforms: Array = data["transforms"]
	if transforms.size() == 0:
		return

	var chunk: Chunk = Chunk.new()
	chunk.node.name = "GrassChunk_%d_%d" % [key.x, key.y]
	chunk.center = data["center"]

	chunk.multimesh.mesh = grass_mesh
	chunk.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	chunk.multimesh.use_colors = true
	chunk.multimesh.use_custom_data = true

	var customs: Array = data["customs"]
	chunk.multimesh.instance_count = transforms.size()
	for i: int in range(transforms.size()):
		chunk.multimesh.set_instance_transform(i, transforms[i])
		chunk.multimesh.set_instance_color(i, Color.WHITE)
		chunk.multimesh.set_instance_custom_data(i, customs[i])
	chunk.multimesh.visible_instance_count = 0  # _update_visible_counts sets the real value next frame

	chunk.multimesh_instance.multimesh = chunk.multimesh
	chunk.multimesh_instance.material_override = grass_material
	chunk.multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	chunk.node.add_child(chunk.multimesh_instance)
	add_child(chunk.node)

	chunks[key] = chunk
