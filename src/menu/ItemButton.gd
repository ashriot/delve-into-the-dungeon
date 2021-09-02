extends PressButton
class_name ItemButton

var empty: bool setget set_empty
var selected: bool setget set_selected
var uses_remain: int setget set_uses_remain
var available: bool setget set_available
var item: Item
var player: Player
var slot_type: int
var ap_cost: = 0

onready var ap_label = $ApCost
onready var uses = $Uses

var default_color: Color
var gold = Color("#ffbe22")
var gray = Color("#606060")

func init(menu):
	.init(menu)
	var _err = connect("pressed", menu, "_on_ItemButton_pressed", [self])

func setup(_player: Player, _item: Item) -> void:
	default_color = $Bg.modulate
	player = _player
	slot_type = player.job_skill
	if _item == null:
		self.empty = true
		return
	item = _item
	$Bg/Sprite.frame = item.frame
	$Title.text = item.name
	var skill = 0
	if player != null:
		skill = max(player.skill[item.sub_type] + int(player.prof[item.sub_type]), 0)
		ap_cost = max(item.ap_cost - skill, 0)
		if player.ap < ap_cost: self.available = false
	ap_label.text = str(ap_cost)
	disabled = false
	if item.max_uses > 0:
		uses.show()
		self.uses_remain = item.uses
		if uses_remain < 1: disabled = true
	else:
		uses.hide()
	self.empty = false
	self.selected = false
	show()

func set_empty(value) -> void:
	empty = value
	if empty:
		if item != null: pass
		item = null
		$Title.text = "[Empty Slot]"

func set_selected(value) -> void:
	selected = value
	if selected: $Bg.modulate = gold
	else: $Bg.modulate = default_color

func set_available(value: bool):
	available = value
	if !selected:
		if available: $Bg.modulate = default_color
		else: $Bg.modulate = gray

# DRAG AND DROP
func get_drag_data(_pos: Vector2):
	tooltip = false
	timer.stop()
	if empty: return
	AudioController.select()
	var data = {
		"origin": self,
		"item": item
	}
	var control = Control.new()
	var drag_control = self.duplicate()
	control.add_child(drag_control)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_control.rect_position = -0.5 * drag_control.rect_size
	drag_control.rect_position += Vector2(0, -8.0)
	set_drag_preview(control)
	return data

func can_drop_data(_position: Vector2, _data) -> bool:
	return true

func drop_data(_position: Vector2, data) -> void:
	if data.item == item:
		AudioController.back()
		return
	AudioController.confirm()
	player.swap_items(item, get_index(), data.item, data.origin.get_index())
	data.origin.setup(player, item)
	setup(player, data.item)

func set_uses_remain(value):
	uses_remain = value
	item.uses = value
	uses.text = "*" + str(uses_remain)
