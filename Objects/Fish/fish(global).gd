extends Node3D

var fish

const RARITY_TIERS := {
	"common": 0,
	"uncommon": 1,
	"rare": 2
}


func _ready() -> void:
	fish = null
	randomize()


func spawn_random_fish(distancefromhome: float) -> void:
	if distancefromhome > 0 and distancefromhome < 70:
		# COMMON TIER
		spawnfish(0)
	elif distancefromhome >= 70 and distancefromhome < 250:
		# UNCOMMON TIER
		spawnfish(1)
	elif distancefromhome >= 250:
		# RARE TIER
		spawnfish(2)

func spawnfish(tier: int = 0) -> void:
	var fish_data := get_random_fish_data(tier)
	if fish_data.is_empty():
		return
	var fish_scene := spawn_fish(fish_data)
	if fish_scene == null:
		return
	fish = fish_scene


func get_random_fish_data(tier: int) -> Dictionary:
	var possible_fish: Array[Dictionary] = []
	var total_spawnrate := 0
	for fish_id in fish_db.fish_db:
		var fish_data: Dictionary = fish_db.get_fish(fish_id)
		var fish_rarity: String = fish_data.get("rarity", "")
		var fish_tier: int = RARITY_TIERS.get(fish_rarity, -1)
		if fish_tier <= tier:
			var spawnrate: int = fish_data.get("spawnrate", 0)
			if spawnrate > 0:
				possible_fish.append(fish_data)
				total_spawnrate += spawnrate
	if possible_fish.is_empty() or total_spawnrate <= 0:
		push_warning("No fish available for tier: " + str(tier))
		return {}
	var random_value := randi_range(1, total_spawnrate)
	for fish_data in possible_fish:
		random_value -= fish_data.get("spawnrate", 0)
		if random_value <= 0:
			return fish_data
	return {}


func spawn_fish(fish_data: Dictionary) -> PackedScene:
	var scene_path: String = fish_data.get("scene", "")
	if scene_path.is_empty():
		push_error("Fish has no scene path: " + str(fish_data))
		return null
	var fish_scene := load(scene_path) as PackedScene
	if fish_scene == null:
		push_error("Could not load fish scene: " + scene_path)
		return null
	var fish_instance := fish_scene.instantiate() as Node3D
	if fish_instance == null:
		push_error("Fish scene is not a Node3D: " + scene_path)
		return null
	add_child(fish_instance)                          # add to tree FIRST
	fish_instance.global_rotation_degrees.x = 90       # then set global transform
	return fish_scene
