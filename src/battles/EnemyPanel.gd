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
	actions = unit.actions
	targetable(false)
	for i in range(actions.size()):
		if actions[i] == null: continue
		var action = actions[i]
		var cd = 0
		if action.starting_cd > 0:
			cd = randi() % (1 + action.starting_cd - action.starting_min) + action.starting_min
		cooldowns[i] = cd
	emit_signal("show_text", "Lv." + str(unit.level), pos, true)
	show()

func level_up() -> void:
	unit.hp_growth = int((unit.base_hp_max() * 0.5 + 5) * (unit.level - 1))
	unit.str_growth = int((unit.base_str() * 0.08 + 0.5) * unit.level - 1)
	unit.agi_growth = int((unit.base_agi() * 0.08 + 0.5) * unit.level - 1)
	unit.int_growth = int((unit.base_int() * 0.08 + 0.5) * unit.level - 1)
	unit.def_growth = int((unit.base_def() * 0.08 + 0.5) * unit.level - 1)

func get_action() -> Action:
	var action = null
	for i in range(actions.size()):
		if actions[i] == null: continue
		if actions[i].cooldown > 0:
			if cooldowns[i] < actions[i].cooldown: cooldowns[i] += 1
			elif action == null:
				cooldowns[i] = 0
				action = actions[i]
		else: continue
	if action == null: action = actions[0]
	return action

func targetable(value: bool, display = true):
	.targetable(value, display)
	if valid_target:
		hit_display.show()
		$HitBG.show()
		dmg_display.show()
	else:
		hit_display.hide()
		$HitBG.hide()
		dmg_display.hide()

func update_dmg_display(hit: Hit):
	if hit == null: return
	var item = hit.item as Item
	var dmg = int((item.multiplier * hit.atk) + hit.bonus_dmg) * (1 + hit.dmg_mod)
	var def = get_stat(item.stat_vs)
	var rel_def = float(def * 1.2) / float(unit.level + 10 + def)
	var def_mod = 1.0 - rel_def
	dmg = int(dmg * def_mod) * hit.item.hits
	dmg_display.max_value = hp_max
	dmg_display.value = clamp(hp_max - hp_cur + dmg, 0, hp_max)
	dmg_display.show()

func update_hit_chance(hit: Hit) -> void:
	if hit == null: return
	if not (enabled or self.alive or valid_target): return
	var value = 100
	if hit.stat_hit != Enum.StatType.NA:
		value = get_hit_and_crit_chance(hit)[0]
	hit_display.text = str(value) + "%"
	update_dmg_display(hit)

func update_status() -> void:
	.update_status()
	if statuses.size() == 0:
		status.hide()
		$StatusBG.hide()
	else:
		status.show()
		$StatusBG.show()

func die():
	.die()
