extends BattlePanel
class_name EnemyPanel

onready var hit_display: = $Hit
onready var dmg_display: = $DmgDisplay
onready var dmg_anim: = $DmgDisplay/AnimationPlayer

var potential_dmg: int
var cooldowns: = {}
var actions: = {}

func init(battle) -> void:
	.init(battle)
	dmg_anim.playback_speed = 1 / GameManager.spd
# warning-ignore:return_value_discarded
	button.connect("pressed", battle, "_on_EnemyPanel_pressed", [self])
# warning-ignore:return_value_discarded
	connect("died", battle, "_on_EnemyPanel_died", [self])

func setup(_unit: Array) -> void:
	if not _unit:
		clear()
		return
	unit = _unit[0].duplicate()
	unit.level = _unit[1]
	level_up()
	.setup(unit)
	self.hp_cur = hp_max
#	self.hp_cur = 1 # DEBUG MODE
	self.ap = unit.ap_init
	actions = unit.actions
	targetable(false)
	for i in range(actions.size()):
		if actions[i] == null: continue
		var action = actions[i]
		var cd = 0
		if action.cooldown > 0:
			cd = randi() % (1 + action.starting_cd - action.starting_min) + action.starting_min
		cooldowns[i] = cd
	emit_signal("show_text", "Lv" + str(unit.level), pos, true)
	show()

func level_up() -> void:
	unit.hp_growth = int((4 + unit.hp_rating) * (4 + unit.level) * (float(unit.level) / 200 + 1))
	unit.str_growth = int(float(2 + unit.str_rating * 1.6) * float(8 + unit.level) / 10)
	unit.agi_growth = int(float(2 + unit.agi_rating * 1.6) * float(8 + unit.level) / 10)
	unit.int_growth = int(float(2 + unit.int_rating * 1.6) * float(8 + unit.level) / 10)
	unit.def_growth = int(float(2 + unit.def_rating * 1.6) * float(8 + unit.level) / 10)
	var cap = int((unit.level + 5) / 10)
	cap = 10
	for key in unit.actions:
		if key > cap: unit.actions[key] = null

func get_action() -> Action:
	var action = null
	for i in range(actions.size() - 1, 0, -1):
		if actions[i] == null: continue
		if cooldowns[i] == 0:
			cooldowns[i] = actions[i].cooldown
			return actions[i]
		elif cooldowns[i] > 0:
			cooldowns[i] -= 1
		else: continue
	if action == null: action = actions[0]
	return action

func targetable(value: bool, display = true):
	.targetable(value, display)
	if valid_target:
		if hit_display.text != "": hit_display.show()
		dmg_display.show()
	else:
		hit_display.hide()
		dmg_display.hide()

func update_hit_chance(hit) -> void:
	if not hit: return
	if not (enabled or self.alive or valid_target): return
	hit.update_target_data(self)
	if hit.action.stat_hit != Enums.StatType.NA:
		hit_display.text = str(int(hit.hit_chance)) + "%"
	else: hit_display.text = ""
	update_dmg_display(hit)

func update_dmg_display(hit):
	if not hit: return
	var item = hit.action as Item
	var kill = false
	if item.name == "Disintegrate":
		if hp_cur <= hit.panel.unit.intellect * 3: kill = true
	elif item.name == "Death Dance":
		if hp_cur <= hit.panel.unit.agility * 1: kill = true
	elif item.name == "Banish":
		if hp_cur <= hit.panel.unit.intellect * 2: kill = true
	var dmg = hp_max - hp_cur + hit.dmg if not kill else hp_max
	dmg_display.max_value = hp_max
	dmg_display.value = clamp(dmg, 0, hp_max)
	dmg_display.show()

func update_status() -> void:
	.update_status()
	if statuses.size() == 0: status.hide()
	else: status.show()

func set_ap(value: int) -> void:
	.set_ap(value)
	ap_gauge.rect_size.x = ap * 3

func set_blocking(value: int) -> void:
	AudioController.play_sfx("block")
	.set_blocking(value)
	if value > 0:
		$Block.rect_size.x = (float(value) / hp_max) * 10
	else:
		$Block.rect_size.x = 0

func get_melee_penalty() -> bool:
	return get_index() > 2
