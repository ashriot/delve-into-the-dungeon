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

func setup(_unit):
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
	emit_signal("show_text", "Lv." + str(unit.level), pos, true)
	show()

func level_up() -> void:
	unit.hp_growth = int((5 + unit.hp_rating) * (4 + unit.level) * (float(unit.level) / 100 + 1))
	print(unit.name, ": ", (5 + unit.hp_rating), " x ", (4 + unit.level), " x ", (float(unit.level) / 100 + 1))
	unit.str_growth = int(float(8 + unit.str_rating) * float(8 + unit.level) / 10)
	unit.agi_growth = int(float(8 + unit.agi_rating) * float(8 + unit.level) / 10)
	unit.int_growth = int(float(8 + unit.int_rating) * float(8 + unit.level) / 10)
	unit.def_growth = int(float(8 + unit.def_rating) * float(8 + unit.level) / 10)
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
		hit_display.show()
		dmg_display.show()
	else:
		hit_display.hide()
		dmg_display.hide()

func update_dmg_display(hit):
	if hit == null: return
	var item = hit.item as Item
	var dmg = int((item.multiplier * hit.atk) + hit.bonus_dmg)
	var def = get_stat(item.stat_vs)
	var def_mod = int(float(def * 0.5) * item.multiplier)
	dmg = int(dmg - def_mod) * (1 + hit.dmg_mod) * hit.item.max_hits
	dmg /= hit.split
	dmg_display.max_value = hp_max
	dmg_display.value = clamp(hp_max - hp_cur + dmg, 0, hp_max)
	dmg_display.show()

func update_hit_chance(hit) -> void:
	if hit == null: return
	if not (enabled or self.alive or valid_target): return
	var value = 100
	if hit.stat_hit != Enums.StatType.NA:
		value = get_hit_and_crit_chance(hit)[0]
	hit_display.text = str(int(value)) + "%"
	update_dmg_display(hit)

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
