extends Control
class_name PlayerMenuPanel

onready var HPCur = $HPCur
onready var HPPercent = $TextureProgress
onready var sprite = $Sprite
onready var selector = $Selector

var tab setget set_tab, get_tab

var unit: Player

func setup(menu, player: Player) -> void:
	unit = player
	sprite.frame = player.frame
	HPCur.text = str(player.hp_cur)
	HPPercent.max_value = player.hp_max
	HPPercent.value = player.hp_cur
	select(false)
# warning-ignore:return_value_discarded
	$Button.connect("pressed", menu, "_on_PlayerMenuPanel_pressed", [self])

func select(value) -> void:
	if value: selector.show()
	else: selector.hide()

func set_tab(value) -> void:
	unit.tab = value

func get_tab() -> int:
	return unit.tab
