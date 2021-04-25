extends Control

signal open_inv

onready var blacksmith = $Blacksmith

onready var map = $WorldMap
onready var hidden = $WorldMap/Nav/Hidden
onready var discovered = $WorldMap/Nav/Discovered
onready var nav = $WorldMap/Nav/Sprite
onready var prev = $WorldMap/Nav/Prev
onready var next = $WorldMap/Nav/Next
onready var scout = $WorldMap/Scout

var game: Game
var map_pos: int setget set_map_pos
var map_max: int

func _ready() -> void:
	blacksmith.hide()
	map.hide()
	scout.hide()

func init(game: Game) -> void:
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
	map_max = game.discovered
	var x = map_max * 6 - 1
	self.map_pos = map_max
	discovered.rect_size.x = x
	map.show()

func _on_Back_pressed():
	AudioController.back()
	map.hide()

func set_map_pos(value) -> void:
	map_pos = value
	nav.position.x = 10 + map_max * 6
	if map_max == 1:
		prev.modulate.a = 0.5
		next.modulate.a = 0.5
	else:
		prev.modulate.a = 1.0
		next.modulate.a = 1.0

func _on_Scout_pressed():
	AudioController.click()
	scout.show()

func _on_ScoutDone_pressed():
	AudioController.back()
	scout.hide()

func _on_Enter_pressed():
	AudioController.confirm()
	game.enter_dungeon()
