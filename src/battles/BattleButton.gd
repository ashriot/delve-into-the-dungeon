extends Button
class_name BattleButton

onready var sprite = $Sprite
onready var title = $Title
onready var title2 = $Selected/Title2
onready var uses = $Uses
onready var uses2 = $Selected/Uses2
onready var selector = $Selected

var item: Item
var uses_remain: int setget set_uses_remain
var selected: bool setget set_selected
var enabled: = false

func init(battle) -> void:
# warning-ignore:return_value_discarded
	connect("pressed", battle, "_on_BattleButton_pressed", [self])

func setup(_item: Item, limited = true) -> void:
	enabled = true
	item = _item
	sprite.frame = item.frame
	title.text = item.name
	title2.text = item.name
	if limited:
		self.uses_remain = item.uses
		if uses_remain < 1: disabled = true
		else: disabled = false
	else:
		uses.hide()
		uses2.hide()
	self.selected = false

func toggle(value) -> void:
	if value and enabled: show()
	else: hide()

func clear() -> void:
	enabled = false
	hide()

func set_uses_remain(value):
	uses_remain = value
	item.uses = value
	uses.text = str(uses_remain)
	uses2.text = str(uses_remain)

func set_selected(value: bool):
	selected = value
	if selected: selector.show()
	else: selector.hide()
