extends Node

var playerInventory = []
var player = null
var playerTotalHoldingCost = 0:
	set(value):
		playerTotalHoldingCost = value
		player.bubbles_counter.text = "Dabloons: " + str(inventory.playerTotalHoldingCost)
