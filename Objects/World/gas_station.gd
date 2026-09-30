extends Node3D

var vehicles_in = []



func _on_refuelling_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("vehicle") and body not in vehicles_in:
		vehicles_in.append(body)
		print(vehicles_in)

func _on_refuelling_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("vehicle"):
		vehicles_in.erase(body)
		print(vehicles_in)
