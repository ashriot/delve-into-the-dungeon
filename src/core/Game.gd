extends Node2D
class_name Game
# GAME.gd

const DamageText = preload("res://src/battles/DamageText.tscn")

onready var title = $CanvasLayer/Title
onready var title_anim = $CanvasLayer/Title/AnimationPlayer
onready var battle = $CanvasLayer/Battle
onready var dungeon = $Dungeon
onready var dungeon_complete = $CanvasLayer/DungeonComplete
onready var menu_button = $CanvasLayer/MenuButton
onready var party_menu = $CanvasLayer/PartyMenu
onready var town_menu = $CanvasLayer/TownMenu
onready var new_hero = $CanvasLayer/NewHero

onready var hud = $CanvasLayer/DungeonHUD
onready var faces = $CanvasLayer/DungeonHUD/Faces
onready var fade = $CanvasLayer/Fade
onready var gold = $CanvasLayer/DungeonHUD/Gold
onready var level = $CanvasLayer/DungeonHUD/Level

onready var profiles = $CanvasLayer/Profiles
onready var profile1 = $CanvasLayer/Profiles/Profiles/Profile1
onready var profile2 = $CanvasLayer/Profiles/Profiles/Profile2
onready var profile3 = $CanvasLayer/Profiles/Profiles/Profile3
onready var new_profile = $CanvasLayer/Profiles/NewProfile

onready var easy_color = $CanvasLayer/Profiles/NewProfile/Difficulty/Easy/Color
onready var norm_color = $CanvasLayer/Profiles/NewProfile/Difficulty/Normal/Color
onready var hard_color = $CanvasLayer/Profiles/NewProfile/Difficulty/Hard/Color
onready var hardcore: = $CanvasLayer/Profiles/NewProfile/Hardcore
onready var hard_desc = $CanvasLayer/Profiles/NewProfile/HardcoreDesc
onready var line_edit = $CanvasLayer/Profiles/NewProfile/LineEdit

signal done_fading
signal done_learned_skill
signal level_changed

export var mute: bool setget set_mute
export var skip_title: bool
export var spd: = 1.0
export(Dictionary) var players

var difficulty: String setget set_difficulty
var slot_num: int
var hardcore_enabled: bool

var hud_timer: = 0.0
var level_num: int setget set_level_num
var dungeon_lvs: = [] setget set_dungeon_lvs
var _Inventory = load("res://src/core/inventory.gd")
var inventory: Inventory = _Inventory.new()

var profile_id: int

func _ready():
#	randomize()
	profiles.hide()
	new_profile.hide()
	fade.show()
	dungeon_complete.hide()
	title.show()
	fade.instant_hide()
	new_hero.hide()
	GameManager.init()
	profile1.init(self, 1)
	profile2.init(self, 2)
	profile3.init(self, 3)
	AudioController.mute = mute
	$CanvasLayer/Profiles/NewProfile/Difficulty/Easy/Btn.connect("pressed", self, "_on_DifficultyBtn_pressed", ["Easy"])
	$CanvasLayer/Profiles/NewProfile/Difficulty/Normal/Btn.connect("pressed", self, "_on_DifficultyBtn_pressed", ["Normal"])
	$CanvasLayer/Profiles/NewProfile/Difficulty/Hard/Btn.connect("pressed", self, "_on_DifficultyBtn_pressed", ["Hard"])
	yield(get_tree().create_timer(0.25), "timeout")
	if skip_title: skip_title()
	else: show_title()

func init() -> void:
	fade.fade_to_black()
	yield(fade, "done")
	profiles.hide()
	title.hide()
	menu_button.show()
	GameManager.initialize_game_data(self)
	GameManager.initialize_inventory()
	GameManager.initialize_party()
	var _err = connect("level_changed", GameManager, "_on_level_changed")
	new_hero.init(self)
	battle.init(self)
	dungeon.init(self)
	party_menu.init(self)
	town_menu.init(self)
	town_menu.show()
	update_hud()
	hud_timer = 3
	AudioController.play_bgm("town")
	fade.fade_from_black()

func show_title() -> void:
	dungeon.active = false
	AudioController.play_bgm("title")
	yield(get_tree().create_timer(1), "timeout")
	title_anim.playback_speed = 0.6
	title_anim.play("FadeIn")
	title.show()
	yield(title_anim, "animation_finished")
	title_anim.playback_speed = 1
	title_anim.play("Flash")
	$CanvasLayer/Title/StartGame.disabled = false

func skip_title():
	AudioController.play_bgm("title")
	title_anim.play("FadeIn")
	title_anim.seek(3.5, true)
	title.show()
	$CanvasLayer/Title/StartGame.disabled = false

func _on_StartGame_pressed():
	AudioController.select()
	profiles.show()

func _physics_process(delta: float) -> void:
	if !dungeon.active: return

	if hud_timer > 2 and !hud.visible: hud.show()
	elif hud_timer < 2 and hud.visible: hud.hide()
	elif hud_timer < 2: hud_timer += 1 * delta

func enter_dungeon(locale: Locale, depth: int) -> void:
	dungeon_complete.hide()
	dungeon.setup(locale, depth)
	self.level_num = depth
	fade.fade_to_black()
	yield(fade, "done")
	town_menu.hide()
	town_menu.map.hide()
	AudioController.play_bgm("dungeon")
	fade.fade_from_black()

func dungeon_complete() -> void:
	fade.fade_to_black()
	yield(fade, "done")
	yield(get_tree().create_timer(0.15), "timeout")
	dungeon_complete.show()
	fade.fade_from_black()
	yield(fade, "done")
	AudioController.play_sfx("dungeon_done")

func battle_start(lv: int):
	menu_button.hide()
	var pos = AudioController.get_pos()
	AudioController.play_bgm("battle")
	fade.fade_to_black()
	yield(fade, "done")
	hud.hide()
	var enemies = get_enemies(lv)
	yield(get_tree().create_timer(0.25), "timeout")
	battle.start(players, enemies)
	fade.fade_from_black()
	yield(fade, "done")
	yield(battle, "battle_done")
	fade.fade_to_black()
	yield(fade, "done")
	battle.hide()
	hud.show()
	yield(get_tree().create_timer(0.5), "timeout")
	AudioController.play_bgm("dungeon", pos)
	fade.fade_from_black()
	dungeon.active = true
	dungeon.collided = false
	update_hud()
	menu_button.show()

func get_enemies(max_lv: int) -> Dictionary:
#	var enemy_picker = dungeon.get_enemies()
	var enemy_picker = load("res://resources/locales/sea_caves.tres").enemies
	var level_num = max_lv
	var mod = int(min(level_num + 2, 6))
	var mobs = randi() % mod + 1
# warning-ignore:integer_division
	var min_lv = max(max_lv - 3, 1)
	var encounter = {}
	for i in range(mobs):
		var slot = 1 if mobs == 1 else i
		var lv = randi() % (1 + max_lv - min_lv) + min_lv
		if mobs == 1 and level_num > 1: lv += 1
		if mobs == 2 and i == 1: slot = 2
		if mobs == 3 and i == 1: slot = (randi() % 2) * 3 + 1
		encounter[slot] = [enemy_picker[randi() % enemy_picker.size()], lv].duplicate()
	return encounter

func _on_Chest_opened() -> void:
# warning-ignore:integer_division
	var lv = int(level_num / 5) + 2
	var item = ItemDb.get_random_item(lv)
	var text = item.name
	if item.item_type == Enums.ItemType.TOME: text = text.insert(0,"Tome of ")
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
	hud_timer = 3

func set_dungeon_lvs(value) -> void:
	dungeon_lvs = value
	emit_signal("level_changed")

func _on_MenuButton_pressed() -> void:
	dungeon.active = false
	AudioController.select()
	party_menu.open_menu()

func close_menu() -> void:
	party_menu.hide()
	update_hud()
	dungeon.active = true

func learned_skill(unit: Player) -> void:
	var next = 7
	var excluding = []
	for i in range(4, 8):
		if unit.items[i] == null:
			if next == 7: next = i
		else: excluding.append(unit.items[i].name)

	var skill = ItemDb.get_item_by_type(unit.job_skill, 1, excluding)
	unit.items[next] = skill
	var skill_name = skill.name
	call_deferred("emit_signal", "done_learned_skill", skill_name) #emit_signal(, skill.name)

func set_mute(value) -> void:
	mute = value
	AudioController.mute = mute

func _exit_tree() -> void:
	pass

func update_hud():
	var i = 0
	for child in faces.get_children():
		if players.size() <= i:
			child.hide()
			continue
		child.show()
		var p = players[i]
		child.get_child(1).frame = p.frame + 20
		child.get_child(2).bbcode_text = get_hp_str(p.hp_cur)
		child.get_child(3).max_value = p.hp_max
		child.get_child(3).value = p.hp_cur
		child.get_child(4).rect_size.x = p.ap * 3
		i += 1
	gold.text = str(inventory.gold)
	level.text = str(level_num)
	hud.show()
	hud_timer = 2.1

func get_hp_str(value: int) -> String:
	if value > 99: return "[right]" + str(value)
	if value > 9: return "[color=#242428]0[/color]" + str(value)
	else: return "[color=#242428]00[/color]" + str(value)

func _on_DifficultyBtn_pressed(value: String) -> void:
	AudioController.click()
	self.difficulty = value

func set_difficulty(value: String) -> void:
	difficulty = value
	easy_color.hide()
	norm_color.hide()
	hard_color.hide()
	var text = "The standard game experience."
	if value == "Easy":
		easy_color.show()
		text = "Enemies are 25% weaker and prices are reduced."
	if value == "Normal":
		norm_color.show()
	if value == "Hard":
		hard_color.show()
		text = "Enemies are 25% stronger and prices are increased."
	$CanvasLayer/Profiles/NewProfile/DifficultyDesc.text = text

func _on_BuyBS_pressed():
	party_menu.open_inv()

func _on_BackToTown_pressed():
	AudioController.play_sfx("stairs")
	fade.fade_to_black()
	yield(fade, "done")
	dungeon_complete.hide()
	town_menu.show()
	fade.fade_from_black()
	AudioController.play_bgm("town")

func _on_ProfileBtn_create_new(slot: int):
	AudioController.select()
	slot_num = slot
	new_profile.show()
	set_difficulty("Normal")
	print("Creating a new save in slot: ", slot)

func _on_ProfileBtn_load_profile(slot: int):
	print("Loading a save from slot: ", slot)
	profile_id = slot
	init()

func _on_ProfileBtn_delete_profile(slot: int):
	print("Deleting a save from slot: ", slot)
	delete_profile(slot)

func create_new_hero():
	new_hero.show()

func _on_add_player(player: Player) -> void:
	var i = players.size()
	players[i] = player
	player.slot = i
	player.heal()
	player.connect("player_changed", GameManager, "_on_player_changed")
	player.changed()

func _on_NewBack_pressed():
	AudioController.back()
	new_profile.hide()

func _on_Hardcore_pressed():
	hardcore_enabled = hardcore.pressed
	if hardcore.pressed:
		AudioController.click()
		$CanvasLayer/Profiles/NewProfile/Hardcore/Label.modulate = Color("#a93b3b")
		hard_desc.text = "Fallen heroes are permanently killed."
	else:
		AudioController.back()
		$CanvasLayer/Profiles/NewProfile/Hardcore/Label.modulate = Color.white
		hard_desc.text = "Fallen heroes can\nbe revived in town."

func _on_LineEdit_text_changed(new_text):
	var result = new_text.length() < 2
	$CanvasLayer/Profiles/NewProfile/Check.disabled = result
#	$Profiles/CreateDialog/Min.modulate.a = 1.0 if result else 0.25

func _on_Check_pressed():
	AudioController.confirm()
	var data = SaveData.new()
	data.game_version = GameManager.VERSION
	data.profile_name = line_edit.text
	data.slot_num = slot_num
	data.hardcore = hardcore_enabled
	data.difficulty = difficulty
	data.discovered = 1
	data.dungeon_lvs = [1, 1, 1, 1, 1, 1, 1]
	data.unlocked_heroes = ["Fighter", "Thief", "Priest", "Wizard", "Sorcerer", "Dancer"]
	data.gold = 0
	if slot_num == 1: profile1.setup(data)
	if slot_num == 2: profile2.setup(data)
	if slot_num == 3: profile3.setup(data)
	save_new_profile(slot_num, data)
	line_edit.clear()
	new_profile.hide()

func save_new_profile(slot: int, save_data: SaveData):
	var path = "user://profile" + str(slot)
	var dir = Directory.new();
	var file_path = path.plus_file("data.tres")
	if dir.file_exists(file_path):
		dir.remove(file_path)
	var error = ResourceSaver.save(file_path, save_data)
	check_error(error)

func delete_profile(slot: int):
	var path = "user://profile" + str(slot)
	var dir = Directory.new();
	var file_path = path.plus_file("data.tres")
	if dir.file_exists(file_path):
		print("Deleting!")
		dir.remove(file_path)

func check_error(error):
	if error != OK:
		print("There was an error writing the save %s." % [error])
