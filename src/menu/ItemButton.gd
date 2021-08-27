extends PressButton


var empty: bool setget set_empty
var selected: bool setget set_selected
var item: Item
var player: Player
var slot_type: int

func init(menu):
	.init(menu)
	var _err = connect("pressed", menu, "_on_ItemButton_pressed", [self])

func setup(_player: Player, _item: Item) -> void:
	player = _player
	slot_type = player.job_skill
	if _item == null:
		self.empty = true
		return
	item = _item
	$Sprite.frame = item.frame
	$Title.text = item.name
	$Selected/Title.text = item.name
	$ApCost.text = str(item.ap_cost)
	self.empty = false
	self.selected = false
	show()

func set_empty(value) -> void:
	empty = value
	if empty:
		if item != null: pass
		item = null
		$Equip.show()
	else: $Equip.hide()

func set_selected(value) -> void:
	selected = value
	if selected: $Selected.show()
	else: $Selected.hide()

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
