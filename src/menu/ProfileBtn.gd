extends Button

signal create_new(slot)
signal load_profile(slot)
signal delete_profile(slot)

onready var slot_1 = $SlotNum1
onready var slot_2 = $SlotNum2
onready var slot_3 = $SlotNum3
onready var save_data = $SaveData
onready var deletion = $Deletion
onready var new_game = $NewGame
onready var profile_name = $SaveData/Name
onready var difficulty = $SaveData/Difficulty
onready var hardcore = $SaveData/Hardcore

var easy = Color("#b6d53c")
var normal = Color("#ffbe22")
var hard = Color("#a93b3b")

var new: = false
var slot_num: int

func init(game: Game, slot: int) -> void:
	self_modulate = game.default_color
	$Deletion/ColorRect.color = game.default_color
	slot_1.self_modulate = game.default_color
	slot_2.self_modulate = game.default_color
	slot_3.self_modulate = game.default_color
	var _err = connect("create_new", game, "_on_ProfileBtn_create_new")
	_err = connect("load_profile", game, "_on_ProfileBtn_load_profile")
	_err = connect("delete_profile", game, "_on_ProfileBtn_delete_profile")
	slot_num = slot
	var data = null
	if slot == 1: data = GameManager.profile1
	elif slot == 2: data = GameManager.profile2
	elif slot == 3: data = GameManager.profile3
	self.setup(data)

func setup(data: SaveData) -> void:
	print("Setting up! ", data)
	deletion.hide()
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
		new = false
		new_game.hide()
		save_data.show()
		profile_name.text = data.profile_name
		$Deletion/ColorRect/ProfName.text = data.profile_name
		difficulty.text = data.difficulty
		if difficulty.text == "Easy": difficulty.modulate = easy
		elif difficulty.text == "Normal": difficulty.modulate = normal
		elif difficulty.text == "Hard": difficulty.modulate = hard
		if data.hardcore: hardcore.show()
		else: hardcore.hide()


func _on_ProfileBtn_pressed():
	if new:
		AudioController.select()
		emit_signal("create_new", slot_num)
	else:
		AudioController.click()
		emit_signal("load_profile", slot_num)

func _on_Delete_pressed():
	AudioController.back()
	deletion.show()

func _on_Cancel_pressed():
	AudioController.back()
	deletion.hide()

func _on_OK_pressed():
	AudioController.play_sfx("stun")
	new = true
	new_game.show()
	save_data.hide()
	deletion.hide()
	emit_signal("delete_profile", slot_num)
