extends Node

@onready var head_marker_location: Marker3D = $"../Armature/Skeleton3D/HeadCosmeticPosition/HeadMarkerLocation"

var hats: Dictionary = {
	"Floral Hat": "res://Assets/Cosmetics/floral_hat.tscn",
	"Wizard Hat": "res://Assets/Cosmetics/WizardHat.blend",
	"Angler Hat": "res://Assets/Cosmetics/AnglerHat.blend",
	"Regular Cap": "res://Assets/Cosmetics/Cap1.blend",
	"WW1 Helmet": "res://Assets/Cosmetics/WW1Helmet.blend"
}

var current_hat: String = "none":
	set(value):
		current_hat = value
		_update_hat()


func _update_hat(): #A setter function
	for child in head_marker_location.get_children():
		child.queue_free()
	if current_hat == "none":
		return
	if not hats.has(current_hat):
		push_warning("Hat doesn't exist: " + current_hat)
		return
	var hat_scene = load(hats[current_hat])
	if hat_scene == null:
		push_error("Couldn't load hat: " + hats[current_hat])
		return
	var hat = hat_scene.instantiate()
	head_marker_location.add_child(hat)
	hat.position = Vector3.ZERO
	hat.rotation = Vector3.ZERO
