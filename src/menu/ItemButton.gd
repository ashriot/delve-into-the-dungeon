extends Button

var equippable: bool setget set_equippable
var selected: bool setget set_selected
var item: Item

func init(menu):
# warning-ignore:return_value_discarded
	connect("pressed", menu, "_on_ItemButton_pressed", [self])

func setup(_item: Item) -> void:
	item = _item
	$Sprite.frame = item.frame
	$Title.text = item.name
	$Selected/Title.text = item.name
	$Uses.text = str(item.uses)
	$Selected/Uses.text = str(item.uses)
	self.equippable = false
	self.selected = false
	show()

func set_equippable(value) -> void:
	equippable = value
	if equippable: $Equip.show()
	else: $Equip.hide()

func set_selected(value) -> void:
	selected = value
	if selected: $Selected.show()
	else: $Selected.hide()
