extends MeshInstance3D

@export var target: Node3D          # player or boat
@export var snap: float = 10.0      # match your water tile/wave size

func _process(_delta: float) -> void:
	if target == null:
		return
	var p: Vector3 = target.global_position
	global_position.x = snappedf(p.x, snap)
	global_position.z = snappedf(p.z, snap)
