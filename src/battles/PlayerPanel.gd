extends Control
class_name PlayerPanel

onready var HPCur = $HPCur
onready var HPPercent = $HPPercent
onready var portrait = $Potrait
onready var selector = $Selector
onready var button = $Button

var hp_max: int
var hp_cur: int setget set_hp_cur
var player: Player

func init(battle, _player: Player):
	player = _player
	portrait.frame = player.frame
	self.hp_max = player.hp_max
	self.hp_cur = player.hp_cur
	HPPercent.max_value = hp_max
	HPPercent.value = hp_cur
	button.connect("pressed", battle, "_on_PlayerPanel_pressed", [self])

func selected(value: bool) -> void:
	if value: selector.show()
	else: selector.hide()

func set_hp_cur(value):
	hp_cur = value
	player.hp_cur = value
	HPCur.text = pad_int(hp_cur, 3)
	HPPercent.value = hp_cur

func pad_int(num: int, digits: int) -> String:
	var text = str(num)
	return text
