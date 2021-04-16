extends PressButton

signal remove_item(item)

var empty: bool setget set_empty
var selected: bool setget set_selected
var item: Item
var slot: int

func init(menu) -> void:
	.init(menu)
	var _err = connect("clicked", menu, "_on_InvButton_clicked", [self])
	_err = connect("remove_item", menu, "_on_InvButton_remove_item")

func setup(_item: Item, _slot: = -1) -> void:
	if _item == null:
		self.empty = true
		return
	item = _item
	slot = _slot
	$Sprite.frame = item.frame
	$Title.text = item.name
	$Selected/Title.text = item.name
	$Uses.text = str(item.uses)
	$Selected/Uses.text = str(item.uses)
	self.empty = false
	self.selected = false
	show()

func set_empty(value) -> void:
	empty = value
	disabled = value
	if empty:
		item = null
		hide()
	else:
		show()

func set_selected(value) -> void:
	selected = value
	if selected: $Selected.show()
	else: $Selected.hide()
