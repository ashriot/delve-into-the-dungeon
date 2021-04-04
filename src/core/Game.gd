extends Control
# GAME.gd

onready var battle = $Battle

export var mute: bool
export(Array, Resource) var players

var _Inventory = load("res://src/core/inventory.gd")
var inventory = _Inventory.new()

func _ready():
	GameManager.initialize_game_data(self)
	GameManager.initialize_inventory()
	GameManager.initialize_party()
	AudioController.mute = mute
	battle.init(self)
