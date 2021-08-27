extends PressButton
class_name BattleButton

onready var sprite = $Sprite
onready var title = $Title
onready var ap_cost = $ApCost
onready var uses = $Uses

var item: Item
var uses_remain: int setget set_uses_remain
var selected: bool setget set_selected
var enabled: = false
var default_color: = Color("#fffbef")

func init(battle) -> void:
	.init(battle)
# warning-ignore:return_value_discarded
	connect("pressed", battle, "_on_BattleButton_pressed", [self])

func setup(_item: Item) -> void:
	enabled = true
	item = _item
	sprite.frame = item.frame
	title.text = item.name
	ap_cost.text = str(item.ap_cost)
	if item.max_uses > 0:
		self.uses_remain = item.uses
		if uses_remain < 1: disabled = true
		else: disabled = false
	else:
		uses.hide()
	self.selected = false
	default_color = modulate

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

func set_selected(value: bool):
	selected = value
	if selected: modulate = Color("#ffbe22")
	else: modulate = default_color
