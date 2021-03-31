extends Button
class_name BattleButton

onready var sprite = $Sprite
onready var title = $Title
onready var uses = $Uses

var action: Action
var uses_remain: int setget set_uses_remain

func init(battle) -> void:
	connect("pressed", battle, "_on_BattleButton_pressed", [self])

func setup(_action: Action) -> void:
	action = _action
	sprite.frame = action.frame
	title.text = action.name
	self.uses_remain = action.uses

func set_uses_remain(value):
	uses_remain = value
	uses.text = str(uses_remain)
