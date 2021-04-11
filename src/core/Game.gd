extends Node2D
# GAME.gd

onready var battle = $CanvasLayer/Battle
onready var dungeon = $Dungeon
onready var menu_button = $CanvasLayer/MenuButton
onready var party_menu = $CanvasLayer/PartyMenu

onready var hud = $CanvasLayer/DungeonHUD
onready var faces = $CanvasLayer/DungeonHUD/Faces
onready var fade = $CanvasLayer/Fade
onready var gold = $CanvasLayer/DungeonHUD/Gold
onready var level = $CanvasLayer/DungeonHUD/Level

signal done_fading

export var mute: bool
export var spd: = 1.0
export(Array, Resource) var players
export(Dictionary) var enemies

var hud_timer: = 0.0
var level_num: = 1 setget set_level_num
var _Inventory = load("res://src/core/inventory.gd")
var inventory = _Inventory.new()

func _ready():
	fade.show()
	GameManager.initialize_game_data(self)
	GameManager.initialize_inventory()
	GameManager.initialize_party()
	AudioController.mute = mute
	battle.init()
	dungeon.init(self)
	party_menu.init(self)
	update_hud()
	AudioController.play_bgm("dungeon")
	hud_timer = 3

func _physics_process(delta: float) -> void:
	if !dungeon.active: return

	if hud_timer > 2 and !hud.visible: hud.show()
	elif hud_timer < 2 and hud.visible: hud.hide()
	elif hud_timer < 2: hud_timer += 1 * delta

func update_hud():
	var i = 0
	for child in faces.get_children():
		var p = players[i]
		child.frame = p.frame + 20
		child.get_child(0).text = str(p.hp_cur)
		child.get_child(1).max_value = p.hp_max
		child.get_child(1).value = p.hp_cur
		i += 1
	gold.text = str(1250)
	level.text = str(level_num)
	hud.show()
	hud_timer = 2.1

func battle_start():
	menu_button.hide()
	dungeon.active = false
	AudioController.play_bgm("battle")
	fade.fade_to_black()
	yield(fade, "done")
	hud.hide()
	yield(get_tree().create_timer(0.25), "timeout")
	battle.start(players, enemies)
	fade.fade_from_black()
	yield(fade, "done")
	yield(battle, "battle_done")
	print("OK DONE!")
	fade.fade_to_black()
	yield(fade, "done")
	battle.hide()
	hud.show()
	yield(get_tree().create_timer(1.5), "timeout")
	AudioController.play_bgm("dungeon")
	fade.fade_from_black()
	dungeon.active = true
	update_hud()
	menu_button.show()

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

func set_level_num(value) -> void:
	level_num = value
	level.text = str(value)

func _on_MenuButton_pressed() -> void:
	dungeon.active = false
	AudioController.click()
	party_menu.open_menu()

func close_menu() -> void:
	party_menu.hide()
	dungeon.active = true
