extends PressButton
class_name BattleButton

onready var bg = $Bg as TextureRect
onready var sprite = $Bg/Sprite as Sprite
onready var quick_icon: = $Quick as Sprite
onready var instant_icon: = $Instant as Sprite
onready var sub_icon: = $SubIcon as Sprite
onready var title = $Title as Label
onready var ap_label = $ApCost as Label
onready var uses = $Uses as Label

var item: Item
var unit: Player
var item_index := 0
var ap_cost: = 0
var uses_remain: int setget set_uses_remain
var selected: bool setget set_selected
var available: bool setget set_available
var enabled: = false

var temp_color: = "#f6b258"

func init(battle) -> void:
	var err = connect("long_pressed", battle, "_on_BattleButton_long_pressed", [self])
	err = connect("pressed", battle, "_on_BattleButton_pressed", [self])
	if err: print("There was an error connecting: ", err)

func setup(_item: Item, index: int, panel: PlayerPanel = null) -> void:
	item = _item
	item_index = index
	enabled = true
	disabled = false
	self.selected = false
	self.available = true
	sprite.frame = item.frame
	title.text = item.name
	if "Step" in item.name:
		sub_icon.show()
		match (item.name):
			"Battle Step": sub_icon.frame = 0
			"Mystic Step": sub_icon.frame = 1
			"Mana Step": sub_icon.frame = 2
			"Butterfly Step": sub_icon.frame = 3
			"Bee Step": sub_icon.frame = 4
	else:
		sub_icon.hide()
	if panel:
		unit = panel.unit
		if item.sub_type == Enums.SubItemType.SORCERY:
			var sp_cur = unit.job_data["sp_cur"]
			if sp_cur > 0:
				title.text += "+" + str(sp_cur)
		if (item.quick or panel.hasted) and panel.quick_actions > 0:
			quick_icon.show()
		else:
			quick_icon.hide()
		if (item.instant):
			instant_icon.show()
		else:
			instant_icon.hide()
		update_ap_cost()
		if item.item_type == Enums.ItemType.MARTIAL_SKILL or \
			item.item_type == Enums.ItemType.WEAPON:
				self.available = not panel.has_bane("Pain") and available
	ap_label.text = str(ap_cost)
	if item.max_uses > 0:
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
	var bp = 0
	if item.sub_type == Enums.SubItemType.PERFORM:
		bp = min(ap_cost, unit.job_data["bp_cur"])
	if item.name == "Draw Arcana":
		ap_cost = max(ap_cost - unit.job_data["arcana"], 0)
	self.available = not (unit.ap < (ap_cost - bp))

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
	elif available: $Bg.modulate = temp_color if item.temporary else Enums.default_color
	else: $Bg.modulate = Enums.gray_color

func set_available(value: bool):
	available = value
	if !selected:
		if available: $Bg.modulate = temp_color if item.temporary else Enums.default_color
		else: $Bg.modulate = Enums.gray_color
