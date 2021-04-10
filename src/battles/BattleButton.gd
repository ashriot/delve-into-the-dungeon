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
	var frame = 70
	match item.item_type:
		Enum.ItemType.WEAPON:
			if item.sub_type == Enum.SubItemType.AXE: frame += 10
			elif item.sub_type == Enum.SubItemType.BOOMERANG: frame += 11
			elif item.sub_type == Enum.SubItemType.BOW: frame += 12
			elif item.sub_type == Enum.SubItemType.DAGGER: frame += 13
			elif item.sub_type == Enum.SubItemType.GUN: frame += 14
			elif item.sub_type == Enum.SubItemType.MACE: frame += 15
			elif item.sub_type == Enum.SubItemType.SPEAR: frame += 16
			elif item.sub_type == Enum.SubItemType.SHIELD: frame += 17
			elif item.sub_type == Enum.SubItemType.SWORD: frame += 18
			elif item.sub_type == Enum.SubItemType.WAND: frame += 19
		Enum.ItemType.MARTIAL_SKILL:
			frame += 0
		Enum.ItemType.SPECIAL_SKILL:
			frame += 1
		Enum.ItemType.TOME:
			if item.sub_type == Enum.SubItemType.AIR: frame += 2
			elif item.sub_type == Enum.SubItemType.ANCIENT: frame += 3
			elif item.sub_type == Enum.SubItemType.ARCANE: frame += 4
			elif item.sub_type == Enum.SubItemType.EARTH: frame += 5
			elif item.sub_type == Enum.SubItemType.FIRE: frame += 6
			elif item.sub_type == Enum.SubItemType.HEALING: frame += 7
			elif item.sub_type == Enum.SubItemType.WATER: frame += 8
			elif item.sub_type == Enum.SubItemType.WITCHCRAFT: frame += 9
		Enum.ItemType.TOOL:
			frame += 30

	sprite.frame = frame
	title.text = item.name
	title2.text = item.name
	if limited: self.uses_remain = item.uses
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
