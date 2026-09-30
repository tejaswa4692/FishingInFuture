extends Node

var playerInventory = []
var player = null
var playerTotalHoldingCost = 3500:
	set(value):
		playerTotalHoldingCost = value
		player.bubbles_counter.text = "Dabloons: " + str(inventory.playerTotalHoldingCost)
