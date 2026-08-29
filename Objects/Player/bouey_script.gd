extends Node

const BOUEY = preload("res://Objects/FloatingBody/bouey.tscn")

@onready var player = get_parent()

var current_bouey: RigidBody3D = null

var reeled_in_fish 

func spawn_booey() -> void:
	player.casted = true
	current_bouey = BOUEY.instantiate()
	current_bouey.global_position = player.bouey_spawner.global_position
	get_tree().root.add_child(current_bouey)

	var direction = -player.bouey_spawner.global_transform.basis.z + Vector3.UP * 0.5
	current_bouey.apply_central_impulse(direction.normalized() * 3.0)

func reel_back_in() -> void:
	if is_instance_valid(current_bouey):
		current_bouey.reel_to(player.bouey_spawner)
		if current_bouey.is_bit:
			var distance_from_home = player.global_position.distance_to(Vector3(0,0,0)) #homme island
			
			print(distance_from_home)
			
			current_bouey.fish_global_.spawn_random_fish(distance_from_home) # This is responsible for spawning the fish
			
			reeled_in_fish = current_bouey.fish_global_.fish #we get the mesh of the fish
			
			#print(reeled_in_fish.resource_path)
			#player.sellable_cost += fish_db.return_cost_via_path(reeled_in_fish.resource_path)
			print(reeled_in_fish.resource_path)
			var caught_fish_data := fish_db.generate_random_fish_data(reeled_in_fish.resource_path)
			inventory.playerInventory.append(caught_fish_data)
			player.display_caught_text(
				caught_fish_data["display_name"],
				caught_fish_data["weight"]
			)
			#We generate random fish data and add it to players inventory where it can be sold later
			
		player.casted = false
