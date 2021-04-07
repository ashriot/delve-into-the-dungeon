extends Node2D
# GAME.gd

onready var battle = $CanvasLayer/Battle

export var mute: bool
export var spd: = 1.0
export(Array, Resource) var players

var _Inventory = load("res://src/core/inventory.gd")
var inventory = _Inventory.new()

func _ready():
	GameManager.initialize_game_data(self)
	GameManager.initialize_inventory()
	GameManager.initialize_party()
	AudioController.mute = mute
#	battle.init(self)
