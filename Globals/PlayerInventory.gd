extends Node

var playerInventory = [{ "display_name": "Yellow Fish", "price": 100.0, "scene": "res://Assets/Fishes/YellowFish/YellowFish.glb", "rarity": "uncommon", "weight": 17 }]
var player = null
var playerTotalHoldingCost = 0:
	set(value):
		playerTotalHoldingCost = value
		player.bubbles_counter.text = "Dabloons: " + str(inventory.playerTotalHoldingCost)
