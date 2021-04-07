extends Node2D
# GAME.gd

onready var battle = $CanvasLayer/Battle
onready var dungeon = $Dungeon

export var mute: bool
export var spd: = 1.0
export(Array, Resource) var players
export(Array, Resource) var enemies

var _Inventory = load("res://src/core/inventory.gd")
var inventory = _Inventory.new()

func _ready():
	GameManager.initialize_game_data(self)
	GameManager.initialize_inventory()
	GameManager.initialize_party()
	AudioController.mute = mute
	dungeon.init(self)

func battle_start():
	battle.init(self)
