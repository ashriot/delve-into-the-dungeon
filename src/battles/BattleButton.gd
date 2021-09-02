extends PressButton
class_name BattleButton

onready var sprite = $Bg/Sprite
onready var title = $Title
onready var ap_label = $ApCost
onready var uses = $Uses

var item: Item
var ap_cost: = 0
var uses_remain: int setget set_uses_remain
var selected: bool setget set_selected
var available: bool setget set_available
var enabled: = false
var default_color: Color
var gold = Color("#ffbe22")
var gray = Color("#606060")

func init(battle) -> void:
	.init(battle)
	default_color = $Bg.modulate
# warning-ignore:return_value_discarded
	connect("pressed", battle, "_on_BattleButton_pressed", [self])

func setup(_item: Item, unit: Player = null) -> void:
	enabled = true
	self.selected = false
	self.available = true
	item = _item
	sprite.frame = item.frame
	title.text = item.name
	var skill = 0
	if unit != null:
		skill = max(unit.skill[item.sub_type] + int(unit.prof[item.sub_type]), 0)
		ap_cost = max(item.ap_cost - skill, 0)
		if unit.ap < ap_cost: self.available = false
	ap_label.text = str(ap_cost)
	disabled = false
	if item.max_uses > 0:
		uses.show()
		self.uses_remain = item.uses
		if uses_remain < 1: disabled = true
	else:
		uses.hide()

func toggle(value) -> void:
	if value and enabled: show()
	else: hide()

func clear() -> void:
	enabled = false
	hide()

func set_uses_remain(value):
	uses_remain = value
	item.uses = value
	uses.text = "*" + str(uses_remain)

func set_selected(value: bool):
	selected = value
	if selected: $Bg.modulate = gold
	elif available: $Bg.modulate = default_color
	else: $Bg.modulate = gray

func set_available(value: bool):
	print("avail: ", value)
	available = value
	if !selected:
		if available: $Bg.modulate = default_color
		else: $Bg.modulate = gray
