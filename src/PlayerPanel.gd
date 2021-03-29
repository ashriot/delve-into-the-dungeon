extends Control

onready var HPCur = $HPCur
onready var HPMax = $HPMax
onready var HPPercent = $HPPercent

var hp_max: int setget set_hp_max
var hp_cur: int setget set_hp_cur

func _ready():
	self.hp_max = 48
	self.hp_cur = 40
	HPPercent.max_value = hp_max
	HPPercent.value = hp_cur

func set_hp_cur(value):
	hp_cur = value
	HPCur.text = pad_int(hp_cur, 3)
	HPPercent.value = hp_cur

func set_hp_max(value):
	hp_max = value
	HPMax.text = pad_int(hp_max, 3)

func pad_int(num: int, digits: int) -> String:
	var text = str(num)
	return text
