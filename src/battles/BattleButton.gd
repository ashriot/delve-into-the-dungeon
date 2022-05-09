extends PressButton
class_name BattleButton

onready var sprite = $Bg/Sprite
onready var quick_icon: = $Quick
onready var title = $Title
onready var ap_label = $ApCost
onready var uses = $Uses

var item: Item
var unit: Player
var item_index := 0
var ap_cost: = 0
var uses_remain: int setget set_uses_remain
var selected: bool setget set_selected
var available: bool setget set_available
var enabled: = false

func init(battle) -> void:
	var err = connect("long_pressed", battle, "_on_BattleButton_long_pressed", [self])
	err = connect("pressed", battle, "_on_BattleButton_pressed", [self])
	if err: print("There was an error connecting: ", err)

func setup(_item: Item, index: int,  _unit: Player = null, quick := false) -> void:
	item = _item
	unit = _unit
	disabled = false
	item_index = index
	enabled = true
	self.selected = false
	self.available = true
	sprite.frame = item.frame
	title.text = item.name
	if item.quick and quick:
		quick_icon.show()
		ap_label.modulate = Enums.quick_color
	else:
		quick_icon.hide()
		ap_label.modulate = Enums.ap_color
	if unit != null:
		update_ap_cost()
	ap_label.text = str(ap_cost)
	if item.max_uses > 0:
		print(item.name, " max uses: ", item.max_uses)
		uses.show()
		self.uses_remain = item.uses
		if uses_remain < 1: disabled = true
	else:
		uses.hide()

func update_ap_cost() -> void:
	if not unit: return
	var skill = 0
	skill = max(unit.skill[item.sub_type], 0)
	ap_cost = max(item.ap_cost - skill, 0)
	if item.name == "Draw Arcana":
		ap_cost = max(ap_cost - unit.job_data["Arcana"], 0)
	self.available = not (unit.ap < ap_cost)

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
