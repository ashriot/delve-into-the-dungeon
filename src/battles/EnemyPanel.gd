extends Control
class_name EnemyPanel

signal done
signal died(panel)
signal show_dmg(text)
signal show_text(text, pos, display)

onready var button: = $Button
onready var sprite: = $Sprite
onready var hp_percent: = $TextureProgress
onready var target: = $Target
onready var anim: = $AnimationPlayer
onready var hit_display: = $Hit
onready var dmg_display: = $DmgDisplay
onready var dmg_anim: = $DmgDisplay/AnimationPlayer

var enemy: Enemy
var hp_cur: int setget set_hp_cur
var hp_max: int
var valid_target: bool
var potential_dmg: int
var pos: Vector2
var cooldowns: = []
var actions: = []

var hexes: Array
var enabled: bool

func init(battle) -> void:
	anim.playback_speed = 1 / GameManager.spd
	dmg_anim.playback_speed = 1 / GameManager.spd
	pos = rect_global_position
	pos.x -= 23
	pos.y += rect_size.y / 2
# warning-ignore:return_value_discarded
	button.connect("pressed", battle, "_on_EnemyPanel_pressed", [self])
# warning-ignore:return_value_discarded
	connect("show_dmg", battle, "show_dmg_text")
# warning-ignore:return_value_discarded
	connect("show_text", battle, "show_text")
# warning-ignore:return_value_discarded
	connect("died", battle, "_on_EnemyPanel_died", [self])

func setup(_enemy: Enemy):
	enabled = true
	enemy = _enemy
	actions = enemy.actions
	level_up()
	targetable(false)
	sprite.frame = enemy.frame
	self.hp_max = enemy.hp_max
	self.hp_cur = enemy.hp_max
	hp_percent.max_value = hp_max
	hp_percent.value = hp_max
	hexes = []
	for i in range(actions.size()):
		var act = actions[i]
		var cd = 0
		if act.starting_cd > 0:
			cd = randi() % (1 + act.starting_cd - act.starting_min) + act.starting_min
		cooldowns.append(cd)
	show()
	emit_signal("show_text", "Lv." + str(enemy.level), pos, true)
	print(_enemy.name, " is enabled and is set up!: ", enabled)

func clear():
	enabled = false
	hide()

func level_up() -> void:
	enemy.hp_growth = int((enemy.base_hp_max() * 0.5 + 5) * (enemy.level-1))
	enemy.str_growth = int((enemy.base_str() * 0.08 + 0.5) * enemy.level)
	enemy.agi_growth = int((enemy.base_agi() * 0.08 + 0.5) * enemy.level)
	enemy.int_growth = int((enemy.base_int() * 0.08 + 0.5) * enemy.level)
	enemy.def_growth = int((enemy.base_def() * 0.08 + 0.5) * enemy.level)

func get_stat(stat) -> int:
	return enemy.get_stat(stat)

func take_hit(hit: Hit, hit_stat: int) -> void:
	var item = hit.item as Item
	var fx = item.sound_fx
	var hit_and_crit = get_hit_and_crit_chance(hit.hit_chance, hit.crit_chance, hit_stat)
	var hit_chance = hit_and_crit[0]
	var crit_chance = hit_and_crit[1]
	var miss = false
	var hit_roll = randi() % 100 + 1
	print(enemy.name, " -> ", hit_roll, "/", hit_chance)
	if hit_roll > hit_chance:
		miss = true
		fx = "miss"
	var dmg = int((item.multiplier * hit.atk) + hit.bonus_dmg) * (1 + hit.dmg_mod)
	var def = get_stat(item.stat_vs)
	var rel_def = float(def - hit.atk) / float(hit.atk) + 0.5 if float(hit.atk) > 0 else 0
	var def_mod = pow(0.95, 27 * rel_def) if def > 0 else 1
	dmg = int(dmg * def_mod)
	var dmg_text = ""
	if not miss:
		self.hp_cur -= dmg
		dmg_text = str(dmg)

		anim.play("Hit")
	else:
		dmg_text = "MISS"
	if item.target_type >= Enum.TargetType.ONE_ENEMY \
		and item.target_type <= Enum.TargetType.ONE_BACK:
		AudioController.play_sfx(fx)
	emit_signal("show_dmg", dmg_text, pos)
	if item.inflict_hexes.size() > 0 and not miss and alive():
		for hex in item.inflict_hexes:
			if randi() % 100 + 1 > hex[2]: continue
			yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
			var success = gain_hex(hex[0], hex[1])
			if success: emit_signal("show_text", "+" + hex[0].name, pos)
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	if hp_cur <= 0:
		die()

func get_action() -> Action:
	var action = null
	for i in range(actions.size()):
		if actions[i].cooldown > 0:
			if cooldowns[i] < actions[i].cooldown: cooldowns[i] += 1
			elif action == null:
				cooldowns[i] = 0
				action = actions[i]
		else: continue
	if action == null: action = actions[0]
	return action

func gain_hex(hex: Effect, duration: int) -> bool:
	if hexes.has(hex.name): return false
	hexes.append([hex, duration])
	if hex.name == "Slow": enemy.agi_bonus -= 5
	return true

func targetable(value: bool, display = true):
	if not enabled: return
	if not alive(): value = false
	valid_target = value
	if valid_target:
		if display: target.show()
		hit_display.show()
		$HitBG.show()
		dmg_display.show()
	else:
		target.hide()
		hit_display.hide()
		$HitBG.hide()
		dmg_display.hide()

func update_dmg_display(hit: Hit):
	var item = hit.item as Item
	var dmg = int((item.multiplier * hit.atk) + hit.bonus_dmg) * (1 + hit.dmg_mod)
	var def = get_stat(item.stat_vs)
	var rel_def = float(def - hit.atk) / hit.atk + 0.5 if hit.atk > 0 else 0
	var def_mod = pow(0.95, 27 * rel_def) if def > 0 else 1
	dmg = int(dmg * def_mod) * hit.item.hits
	dmg_display.max_value = hp_max
	dmg_display.value = clamp(hp_max - hp_cur + dmg, 0, hp_max)
	dmg_display.show()

func update_hit_chance(hit: Hit) -> void:
	if not (enabled or alive() or valid_target): return
	var value = 100
	if hit.stat_hit != Enum.StatType.NA:
		value = get_hit_and_crit_chance(hit.hit_chance, 0, hit.stat_hit)[0]
	hit_display.text = str(value) + "%"
	update_dmg_display(hit)

func get_hit_and_crit_chance(hit_chance: int, crit_chance: int, stat) -> Array:
	var hit = 100
	var crit = 0
	if stat != Enum.StatType.NA:
		hit = clamp(hit_chance - (get_stat(stat) * 5), 0, 100)
		crit = crit_chance
	return [hit, crit]

func alive() -> bool:
	return hp_cur > 0

func die():
	emit_signal("died")
	hide()

func set_hp_cur(value: int):
	hp_cur = int(clamp(value, 0, hp_max))
	hp_percent.value = value
