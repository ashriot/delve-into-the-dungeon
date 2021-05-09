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

func init(game: Game, slot: int) -> void:
	connect("create_new", game, "_on_ProfileBtn_create_new")
	connect("load_profile", game, "_on_ProfileBtn_load_profile")
	slot_num = slot
	self.setup(null)

func setup(data: SaveData) -> void:
	slot_1.hide()
	slot_2.hide()
	slot_3.hide()
	if slot_num == 1: slot_1.show()
	if slot_num == 2: slot_2.show()
	if slot_num == 3: slot_3.show()
	if data == null:
		new = true
		new_game.show()
		save_data.hide()
	else:
		new_game.hide()
		save_data.show()
		profile_name.text = data.profile_name
		difficulty.text = data.difficulty
		gold.text = str(data.gold)
		if data.hardcore: hardcore.show()


func _on_ProfileBtn_pressed():
	if new:
		AudioController.select()
		emit_signal("create_new", slot_num)
	else:
		AudioController.click()
		emit_signal("load_profile", slot_num)
	
