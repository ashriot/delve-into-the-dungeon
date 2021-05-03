extends Button

signal create_new(slot)
signal load_profile(slot)

onready var slot_1 = $SlotNum1
onready var slot_2 = $SlotNum2
onready var slot_3 = $SlotNum3
onready var save_data = $SaveData
onready var new_game = $NewGame
onready var profile_name = $SaveData/Name
onready var difficulty = $SaveData/Difficulty
onready var gold = $SaveData/Gold
onready var hardcore = $SaveData/Hardcore

var new: = false
var slot_num: int

func init(game: Game, profile: Profile) -> void:
	connect("create_new", game, "_on_ProfileBtn_create_new")
	connect("load_profile", game, "_on_ProfileBtn_load_profile")
	if profile == null:
		new = true
		new_game.show()
		return
	else: new_game.hide()
	slot_1.hide()
	slot_2.hide()
	slot_3.hide()
	slot_num = profile.slot_num
	if slot_num == 1: slot_1.show()
	if slot_num == 2: slot_2.show()
	if slot_num == 3: slot_3.show()
	
	profile_name.text = profile.name
	difficulty.text = profile.difficulty
	gold.text = str(profile.gold)
	if profile.hardcore: hardcore.show()


func _on_ProfileBtn_pressed():
	if new:
		AudioController.select()
		emit_signal("create_new", slot_num)
	else:
		AudioController.click()
		emit_signal("load_profile", slot_num)
	
