extends BattlePanel
class_name PlayerPanel

onready var hp_cur_display = $HPCur
onready var selector = $Selector
onready var outline = $Outline

var tab: int setget set_tab, get_tab

var ready:= true setget set_ready
var selected:= false setget set_selected

func init(battle):
	.init(battle)
	anim.playback_speed = 1 / GameManager.spd
	pos = rect_global_position
	pos.x -= 16
	pos.y += rect_size.y / 2
# warning-ignore:return_value_discarded
	button.connect("pressed", battle, "_on_PlayerPanel_pressed", [self])
# warning-ignore:return_value_discarded
	connect("died", battle, "_on_PlayerPanel_died", [self])

func setup(_unit):
	unit = _unit
	.setup(_unit)
	self.selected = false
	self.ready = true

func update_status() -> void:
	.update_status()
	if statuses.size() == 0: status.frame = 90

func set_selected(value: bool):
	if !ready: return
	selected = value
	if selected: selector.show()
	else: selector.hide()

func set_ready(value: bool):
	ready = value
	if ready:
		if sprite.frame > 10:
			sprite.frame -= 10
		outline.modulate.a = 1
		if blocking > 0: self.blocking = 0
		decrement_boons("Start")
	else:
		if sprite.frame < 10:
			sprite.frame += 10
		outline.modulate.a = 0.15

func set_hp_cur(value):
	.set_hp_cur(value)
	unit.hp_cur = value
	if blocking > 0:
		hp_cur_display.modulate = Color.slategray
		hp_cur_display.text = str(blocking)
	else:
		hp_cur_display.modulate = Color.white
		hp_cur_display.text = str(hp_cur)

func die() -> void:
	.die()

func victory() -> void:
	if !ready: self.ready = true
	anim.play("Victory")

func set_tab(value) -> void:
	unit.tab = value

func get_tab() -> int:
	return unit.tab

func get_melee_penalty() -> bool:
	return get_index() > 1
