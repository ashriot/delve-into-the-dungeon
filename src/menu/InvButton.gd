extends PressButton
class_name InvButton

var empty: bool setget set_empty
var selected: bool setget set_selected
var uses_remain: int setget set_uses_remain
var available: bool setget set_available
var item: Item
var player: Player
var slot: int
var ap_cost: = 0

onready var ap_label = $ApCost
onready var uses = $Uses

func init(menu) -> void:
	.init(menu)
	var _err = connect("pressed", menu, "_on_InvButton_pressed", [self])

func setup(_item: Item, _slot: = -1) -> void:
	item = _item
	slot = _slot
	uses.hide()
	ap_label.show()
	self.available = true
	if _item == null:
		self.empty = true
		return
	$Bg/Sprite.show()
	$Bg/Sprite.frame = item.frame
	$Title.text = item.name
	var skill = 0
	if player != null:
		skill = max(player.skill[item.sub_type] + int(player.prof[item.sub_type]), 0)
		ap_cost = max(item.ap_cost - skill, 0)
		if item.sub_type == Enum.SubItemType.TOOL: ap_cost = 0
	ap_label.text = str(ap_cost)
	disabled = false
	if item.max_uses > 0:
		uses.show()
		self.uses_remain = item.uses
		if uses_remain < 1: disabled = true
	self.empty = false
	self.selected = false
	show()

func set_empty(value) -> void:
	empty = value
	if empty:
		self.available = true
		if item != null: pass
		item = null
		$Title.text = ""
		ap_label.hide()
		$Bg/Sprite.hide()

func set_selected(value) -> void:
	selected = value
	if selected: $Bg.modulate = GameManager.gold
	else: $Bg.modulate = GameManager.ui_color

func set_available(value: bool):
	available = value
	if !selected:
		if available: $Bg.modulate = GameManager.ui_color
		else: $Bg.modulate = GameManager.gray

func toggle(value) -> void:
	if value: show()
	else: hide()

func set_uses_remain(value):
	uses_remain = value
	item.uses = value
	uses.text = "*" + str(uses_remain)
