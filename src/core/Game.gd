extends Node2D
# GAME.gd

onready var battle = $CanvasLayer/Battle
onready var dungeon = $Dungeon
onready var fade = $Dungeon/CanvasLayer/Fade

signal done_fading

export var mute: bool
export var spd: = 1.0
export(Array, Resource) var players
export(Dictionary) var enemies

var _Inventory = load("res://src/core/inventory.gd")
var inventory = _Inventory.new()

func _ready():
	fade.instant_show()
	GameManager.initialize_game_data(self)
	GameManager.initialize_inventory()
	GameManager.initialize_party()
	AudioController.mute = mute
	battle.init(self)
	dungeon.init(self)
	AudioController.play_bgm("dungeon")

func battle_start():
	dungeon.active = false
	AudioController.play_bgm("battle")
	fade.fade_to_black()
	yield(fade, "done")
	dungeon.hud.hide()
	yield(get_tree().create_timer(1), "timeout")
	battle.start(players, enemies)
	fade.fade_from_black()
	yield(fade, "done")
	yield(battle, "battle_done")
	print("OK DONE!")
	fade.fade_to_black()
	yield(fade, "done")
	battle.hide()
	dungeon.hud.show()
	yield(get_tree().create_timer(1.5), "timeout")
	AudioController.play_bgm("dungeon")
	fade.fade_from_black()
	dungeon.active = true

func _on_FadeOut() -> void:
	print("Fading out")
	fade.fade_to_black()
	yield(fade, "done")
	emit_signal("done_fading")

func _on_FadeIn() -> void:
	print("Fading in")
	fade.fade_from_black()
	yield(fade, "done")
	emit_signal("done_fading")
