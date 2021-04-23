extends Control

signal open_inv

onready var blacksmith = $Blacksmith

var game

func _ready() -> void:
	blacksmith.hide()

func init(game) -> void:
	self.game = game
	connect("open_inv", game, "_on_BuyBS_pressed")

func _on_Blacksmith_pressed():
	AudioController.click()
	blacksmith.show()

func _on_Leave_BS_pressed():
	AudioController.back()
	blacksmith.hide()

func _on_BuyBS_pressed():
	AudioController.click()
	emit_signal("open_inv")

func _on_SellBS_pressed():
	AudioController.click()
	emit_signal("open_inv")


func _on_TownGates_pressed():
	AudioController.click()
	hide()
