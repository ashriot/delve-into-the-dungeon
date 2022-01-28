extends PressButton
class_name BattleButton

onready var sprite = $Bg/Sprite
onready var quick_icon: = $Quick
onready var title = $Title
onready var ap_label = $ApCost
onready var uses = $Uses

var item: Item
var ap_cost: = 0
var uses_remain: int setget set_uses_remain
var selected: bool setget set_selected
var available: bool setget set_available
var enabled: = false

func init(battle) -> void:
	var err = connect("long_pressed", battle, "_on_BattleButton_long_pressed", [self])
	err = connect("pressed", battle, "_on_BattleButton_pressed", [self])
	if err: print("There was an error connecting: ", err)

func setup(_item: Item, unit: Player = null, quick := false) -> void:
	enabled = true
	self.selected = false
	self.available = true
	item = _item
	sprite.frame = item.frame
	title.text = item.name
	if item.quick and quick:
		quick_icon.show()
		ap_label.modulate = Enums.yellow_color
	else:
		quick_icon.hide()
		ap_label.modulate = Enums.ap_color
	var skill = 0
	if unit != null:
		skill = max(unit.skill[item.sub_type], 0)
		ap_cost = max(item.ap_cost - skill, 0)
		if ap_cost == 0: ap_label.self_modulate.a = 0.5
		else: ap_label.self_modulate.a = 1.0
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
	if selected: $Bg.modulate = Enums.yellow_color
	elif available: $Bg.modulate = Enums.default_color
	else: $Bg.modulate = Enums.gray_color

func set_available(value: bool):
	available = value
	if !selected:
		if available: $Bg.modulate = Enums.default_color
		else: $Bg.modulate = Enums.gray_color
