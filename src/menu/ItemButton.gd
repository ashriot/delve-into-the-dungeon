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

func init(menu):
	var err = connect("long_pressed", menu, "_on_ItemButton_long_pressed", [self])
	err = connect("pressed", menu, "_on_ItemButton_pressed", [self])
	if err: print("There was an error connecting: ", err)

func setup(_player: Player, _item: Item) -> void:
	player = _player
	slot_type = player.job_skill
	uses.hide()
	ap_label.show()
	self.available = true
	if _item == null:
		self.empty = true
		modulate.a = 0.25
		return
	modulate.a = 1.0
	item = _item
	$Bg/Sprite.show()
	$Bg/Sprite.frame = item.frame
	$Title.text = item.name
	var skill = 0
	if player != null:
		skill = player.skill[item.sub_type]
		ap_cost = max(item.ap_cost - skill, 0)
		if item.sub_type == Enums.SubItemType.TOOL: ap_cost = 0
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
