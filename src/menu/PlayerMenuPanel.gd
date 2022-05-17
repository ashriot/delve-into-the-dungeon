extends Control
class_name PlayerMenuPanel

onready var HpCur = $HpCur
onready var HpGauge = $HpGauge
onready var ApGauge = $ApGauge
onready var sprite = $Sprite
onready var selector = $Selector

var tab setget set_tab, get_tab

var menu
var unit: Player

func init(menu) -> void:
	self.menu = menu
# warning-ignore:return_value_discarded
	$Button.connect("pressed", menu, "_on_PlayerMenuPanel_pressed", [self])

func setup(player: Player) -> void:
	unit = player
	sprite.frame = player.frame
	HpCur.bbcode_text = get_hp_str(player.hp_cur)
	ApGauge.rect_size.x = player.ap * 2
	HpGauge.max_value = player.hp_max
	HpGauge.value = player.hp_cur

func get_hp_str(value: int) -> String:
	if value > 99: return "[right]" + str(value)
	if value > 9: return "[color=#242428]0[/color]" + str(value)
	else: return "[color=#242428]00[/color]" + str(value)

func select(value) -> void:
	if value: selector.show()
	else: selector.hide()

func set_tab(value) -> void:
	unit.tab = value

func get_tab() -> int:
	return unit.tab

# DRAG AND DROP
func get_drag_data(_pos: Vector2):
	AudioController.select()
	var data = {
		"origin": self,
		"unit": unit
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
	if data.unit == unit:
		AudioController.back()
		return
	AudioController.confirm()
	menu.swap_players(unit, data.unit)
	data.origin.setup(unit)
	setup(data.unit)
	if selector.visible:
		menu.select_player(data.origin)
	elif data.origin.selector.visible:
		menu.select_player(self)
