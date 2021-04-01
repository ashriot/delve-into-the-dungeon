extends Button
class_name BattleButton

onready var sprite = $Sprite
onready var sprite2 = $Selected/Sprite2
onready var title = $Title
onready var title2 = $Selected/Title2
onready var uses = $Uses
onready var uses2 = $Selected/Uses2
onready var selector = $Selected

var item: Item
var uses_remain: int setget set_uses_remain
var selected: bool setget set_selected

func init(battle) -> void:
	connect("pressed", battle, "_on_BattleButton_pressed", [self])

func setup(_item: Item) -> void:
	item = _item
	sprite.frame = item.frame
	sprite2.frame = item.frame
	title.text = item.name
	title2.text = item.name
	self.uses_remain = item.uses
	self.selected = false

func set_uses_remain(value):
	uses_remain = value
	uses.text = str(uses_remain)
	uses2.text = str(uses_remain)

func set_selected(value: bool):
	selected = value
	print("button selected: ", value)
	if selected: selector.show()
	else: selector.hide()
