extends PressButton
class_name BattleButton

onready var sprite = $Bg/Sprite
onready var quick_icon: = $Quick
onready var instant_icon: = $Instant
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

func init(ui) -> void:
	var err = connect("long_pressed", ui, \
		"_on_BattleButton_long_pressed", [self])
	err = connect("pressed", ui, "_on_BattleButton_pressed", [self])
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
	if panel:
		unit = panel.unit
		if item.sub_type == Enums.SubItemType.SORCERY:
			var sp_cur = unit.job_data["sp_cur"]
			if sp_cur > 0:
				title.text += "+" + str(sp_cur)
		instant_icon.visible = item.instant or \
			(panel.hasted and item.quick)
		quick_icon.visible = (item.quick or panel.hasted) \
			and panel.quick_actions > 0
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
	elif available: $Bg.modulate = Enums.default_color
	else: $Bg.modulate = Enums.gray_color

func set_available(value: bool):
	available = value
	if !selected:
		if available: $Bg.modulate = Enums.default_color
		else: $Bg.modulate = Enums.gray_color
