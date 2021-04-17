extends Node2D
# GAME.gd

var DamageText = preload("res://src/battles/DamageText.tscn")

var goblin = preload("res://resources/enemies/goblin.tres")
var gargoyle = preload("res://resources/enemies/gargoyle.tres")
var mermaid = preload("res://resources/enemies/mermaid.tres")
var pixie = preload("res://resources/enemies/pixie.tres")

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

func _exit_tree() -> void:
	pass

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
	var enemies = get_enemies()
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
	yield(get_tree().create_timer(0.5), "timeout")
	AudioController.play_bgm("dungeon")
	fade.fade_from_black()
	dungeon.active = true
	dungeon.collided = false
	update_hud()
	menu_button.show()

func get_enemies() -> Dictionary:
	var lv = int(level_num / 3) + 1
	var mob0 = [goblin, randi() % 2 + lv]
	var mob1 = [gargoyle, randi() % 2 + lv] if randi() % 2 > 0 else null
	var mob2 = [goblin, randi() % 2 + lv] if randi() % 2 > 0 else null
	return {
		0: mob0,
		1: mob1,
		2: mob2,
	}

func _on_Chest_opened() -> void:
	var item = ItemDb.get_random_item(level_num + 1)
	var text = item.name
	if item.item_type == Enum.ItemType.TOME: text = text.insert(0,"Tome of ")
	found(text)
	inventory.add_item(item.name)

func found(text: String) -> void:
	var damage_text = DamageText.instance()
	add_child(damage_text)
	damage_text.rect_position = dungeon.player_pos
	damage_text.rect_position.x -= damage_text.rect_size.x / 2 - 4
	damage_text.found(text)

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
	AudioController.select()
	party_menu.open_menu()

func close_menu() -> void:
	party_menu.hide()
	dungeon.active = true
