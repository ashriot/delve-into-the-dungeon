extends Control
class_name BattlePanel

signal done
signal died(panel)
signal show_dmg(text)
signal show_text(text, pos, display)

var arcanum = preload("res://resources/actions/skills/arcana/arcanum.tres")

onready var button: = $Button
onready var hp_gauge: = $HpGauge
onready var ap_gauge = $ApGauge
onready var target: = $Target
onready var sprite: = $Sprite
onready var anim: = $AnimationPlayer

onready var status = $Status

var enabled: bool
var alive: bool setget, get_alive
var unit: Unit = null
var hp_cur: int setget set_hp_cur
var hp_max: int
var ap: int setget set_ap
var valid_target: bool
var melee_penalty: bool setget, get_melee_penalty
var pos: Vector2

var banes: Array
var boons: Array
var statuses: = []
var delay: = 0.0
var status_ptr: int
var blocking: int setget set_blocking

func init(battle) -> void:
	anim.playback_speed = 1 / GameManager.spd
	pos = rect_global_position
	pos.x -= 23
	pos.y += rect_size.y / 2
# warning-ignore:return_value_discarded
	connect("show_dmg", battle, "show_dmg_text")
# warning-ignore:return_value_discarded
	connect("show_text", battle, "show_text")

func setup(_unit):
	anim.stop()
	sprite.visible = true
	enabled = true
	sprite.frame = unit.frame
	self.hp_max = unit.hp_max
	self.ap = unit.ap
	hp_gauge.max_value = hp_max
	hp_gauge.value = hp_max
	blocking = 0
	banes.clear()
	boons.clear()
	statuses.clear()
	update_status()

func clear():
	enabled = false
	hide()

func _physics_process(delta: float) -> void:
	if statuses.size() == 0: return
	if delay < 0.1:
		status_ptr = (status_ptr + 1) % statuses.size()
		status.frame = statuses[status_ptr][1]
		delay = float(1.25 * GameManager.spd)
	else: delay -= 1.0 * delta

func _exit_tree() -> void:
	queue_free()

func get_stat(stat) -> int:
	return unit.get_stat(stat)

func take_hit(hit) -> bool:
	var gained_xp = false
	var item = hit.item as Action
	var effect_only = item.damage_type == Enums.DamageType.EFFECT_ONLY
	var fx = item.sound_fx
	var hit_and_crit = get_hit_and_crit_chance(hit)
	var hit_chance = hit_and_crit[0]
	var crit_chance = hit_and_crit[1]
	var lifesteal = hit.item.lifesteal
	var miss = false
	var hit_roll = randi() % 100 + 1
	if hit_roll > hit_chance: miss = true
	var multi = item.multiplier
	if item.name == "Fireball":
		if has_bane("Burn"):
			multi *= 2
	var dmg = float((multi * hit.atk) + hit.bonus_dmg)
	var def = get_stat(item.stat_vs)
	var def_mod = float(def * 0.5) * multi
	print(hit.user.unit.name, " uses ", hit.item.name, " -> Base ATK: ", hit.atk, " x ", multi, " = ", dmg)
	dmg = max(int((dmg - def_mod) * (1 + hit.dmg_mod)), 0)
	dmg /= hit.split
	var lifesteal_heal = int(float(min(dmg, hp_cur)) * lifesteal)
	print(unit.name, " -> Base DEF: ", unit.get_stat(item.stat_vs), " DEF: ", float(def * .8) * multi, " DMG: ", dmg)
	var dmg_text = ""
	if not miss and !effect_only:
		if blocking > 0:
			if blocking >= dmg:
				self.blocking -= dmg
				dmg = 0
			else:
				dmg -= blocking
				self.blocking = 0
		if dmg > 0: gained_xp = true
		self.hp_cur -= dmg
		dmg_text = str(dmg)
		anim.play("Hit")
	elif miss:
		dmg_text = "MISS"
		fx = "miss"
	emit_signal("show_dmg", dmg_text, pos)
	if lifesteal_heal > 0:
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
		hit.user.take_healing(lifesteal_heal)
	if item.target_type >= Enums.TargetType.ONE_ENEMY \
		and item.target_type <= Enums.TargetType.ONE_BACK \
		or item.target_type == Enums.TargetType.RANDOM_ENEMY:
		AudioController.play_sfx(fx)
	if item.inflict_banes.size() > 0 and not miss and self.alive:
		for bane in item.inflict_banes:
			if randi() % 100 + 1 > bane[2]: continue
			if not effect_only: yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
			var success = gain_bane(bane[0], bane[1])
			if success:
				emit_signal("show_text", "+" + bane[0].name, pos)
				gained_xp = true
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	if item.gain_boons.size() > 0 and not miss:
		for boon in item.gain_boons:
			if randi() % 100 + 1 > boon[2]: continue
			if not effect_only: yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
			var success = hit.user.gain_boon(boon[0], boon[1])
			if success: emit_signal("show_text", "+" + boon[0].name, hit.user_pos)
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	return gained_xp

func take_friendly_hit(user: BattlePanel, item: Action) -> void:
	if item.name == "Draw Arcana":
		user.unit.job_data["Arcana"] = 0
		for i in range(5, 10):
			user.unit.items[i] = arcanum
	var dmg = int(item.multiplier * user.get_stat(item.stat_used) + item.bonus_damage)
	var def = int(get_stat(item.stat_vs) * item.multiplier) if item.stat_vs != Enums.StatType.NA else 0
	if item.name == "Healing Haka":
		def = int(float(hp_max - hp_cur) * 0.33)
	var dmg_text = ""
	if item.damage_type == Enums.DamageType.HEAL:
		dmg += def
		self.hp_cur += dmg
		dmg_text = str(dmg)
	elif item.damage_type == Enums.DamageType.BLOCK:
		dmg_text = str(dmg)
		self.blocking = max(blocking, dmg)
	if dmg > 0:
		emit_signal("show_text", "+" + dmg_text, pos)
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	self.ap += item.grant_ap
	if item.inflict_banes.size() > 0:
		for bane in item.inflict_banes:
			if randi() % 100 + 1 > bane[2]: continue
			var success = gain_bane(bane[0], bane[1])
			if success: emit_signal("show_text", "+" + bane[0].name, pos)
		yield(get_tree().create_timer(0.5 * GameManager.spd, false), "timeout")
	if item.inflict_boons.size() > 0:
		for boon in item.inflict_boons:
			if randi() % 100 + 1 > boon[2]: continue
			var success = gain_boon(boon[0], boon[1])
			if success: emit_signal("show_text", "+" + boon[0].name, pos)
			if item.inflict_boons.find(boon) < item.inflict_boons.size() - 1:
				yield(get_tree().create_timer(0.25 * GameManager.spd, false), "timeout")
	yield(get_tree().create_timer(0.25 * GameManager.spd, false), "timeout")
	emit_signal("done")

func take_healing(amt: int) -> void:
	self.hp_cur += amt
	if amt != 0: emit_signal("show_text", "+" + str(amt), pos)

func take_damage(amt: int) -> void:
	if !enabled: return
	self.hp_cur -= amt
	if amt != 0: emit_signal("show_dmg", str(amt), pos)

func gain_bane(bane: Effect, duration: int) -> bool:
	var found = false
	for h in banes: if h[0].name == bane.name:
		found = true
		if h[1] < duration: h[1] = duration
		else: return false
	if not found:
		var applied = true
		if bane.name == "Dull":
			if has_boon("Wise"):
				remove_boon(get_boon("Wise"))
				applied = false
			else: unit.int_mods.append(0.75)
		elif bane.name == "Frail":
			if has_boon("Safe"):
				remove_boon(get_boon("Safe"))
				applied = false
			else: unit.def_mods.append(0.75)
		elif bane.name == "Slow":
			if has_boon("Fast"):
				remove_boon(get_boon("Fast"))
				applied = false
			else: unit.agi_mods.append(0.75)
		elif bane.name == "Weak":
			if has_boon("Bold"):
				remove_boon(get_boon("Bold"))
				applied = false
			else: unit.str_mods.append(0.75)
		if applied:
			add_status([bane.name, bane.frame])
			banes.append([bane, duration])
	return true

func has_bane(bane_name: String) -> bool:
	for bane in banes:
		if bane[0].name == bane_name: return true
	return false

func get_bane(bane_name:String) -> Effect:
	for bane in banes:
		if bane[0].name == bane_name: return bane[0]
	return null

func get_boon(boon_name:String) -> Effect:
	for boon in boons:
		if boon[0].name == boon_name: return boon[0]
	return null

func has_boon(boon_name: String) -> bool:
	for boon in boons:
		if boon[0].name == boon_name: return true
	return false

func gain_boon(boon: Effect, duration: int) -> bool:
	var found = false
	for b in boons: if b[0].name == boon.name:
		found = true
		if b[1] < duration: b[1] = duration
		else: return false
	if not found:
		var applied = true
		if boon.name == "Bold":
			if has_bane("Weak"):
				remove_bane(get_bane("Weak"))
				applied = false
			else: unit.str_mods.append(1.25)
		elif boon.name == "Fast":
			if has_bane("Slow"):
				remove_bane(get_bane("Slow"))
				applied = false
			else: unit.agi_mods.append(1.25)
		elif boon.name == "Safe":
			if has_bane("Frail"):
				remove_bane(get_bane("Frail"))
				applied = false
			else: unit.def_mods.append(1.25)
		elif boon.name == "Wise":
			if has_bane("Dull"):
				remove_bane(get_bane("Dull"))
				applied = false
			else: unit.int_mods.append(1.25)
		if applied:
			add_status([boon.name, boon.frame])
			boons.append([boon, duration])
	return true

func decrement_boons(timing: String) -> void:
	for boon in boons:
		if (boon[0].turn_end and timing == "End") or \
			(boon[0].turn_start and timing == "Start"):
				print(boon[0].name, " -> ", boon[1])
				boon[1] -= 1
				if boon[1] == 0:
					remove_boon(boon[0])
	emit_signal("done")

func decrement_banes(timing: String) -> void:
	for bane in banes:
		if (bane[0].turn_end and timing == "End") or \
			(bane[0].turn_start and timing == "Start"):
				bane[1] -= 1
				if bane[0].triggered:
					trigger_bane(bane[0].name)
					yield(get_tree().create_timer(0.25, true), "timeout")
				if bane[1] == 0:
					remove_bane(bane[0])
	call_deferred("emit_signal", "done")

func trigger_bane(bane_name: String) -> void:
	if bane_name == "Bleed":
		AudioController.play_sfx("gash")
		take_damage(int(float(hp_max) * 0.1))
		yield(get_tree().create_timer(0.15, true), "timeout")
	if bane_name == "Burn":
		AudioController.play_sfx("fire")
		take_damage(unit.get_highest() * 0.5)
		yield(get_tree().create_timer(0.15, true), "timeout")
	if bane_name == "Poison":
		AudioController.play_sfx("poison")
		take_damage(max(int(float(hp_cur) * 0.2), 1))
		yield(get_tree().create_timer(0.15, true), "timeout")

func remove_boon(find: Effect) -> void:
	for boon in boons:
		if boon[0] == find:
			boons.remove(boons.find(boon))
			break
	for s in statuses:
		if s[0] == find.name:
			remove_status(find.name)
			break
	if find.name == "Bold": unit.str_mods.remove(unit.str_mods.find(1.25))
	elif find.name == "Fast": unit.agi_mods.remove(unit.agi_mods.find(1.25))
	elif find.name == "Safe": unit.def_mods.remove(unit.def_mods.find(1.25))
	elif find.name == "Wise": unit.int_mods.remove(unit.int_mods.find(1.25))

func remove_bane(find: Effect) -> void:
	for bane in banes:
		if bane[0] == find:
			banes.remove(banes.find(bane))
			break
	for s in statuses:
		if s[0] == find.name:
			remove_status(find.name)
			break
	if find.name == "Weak": unit.str_mods.remove(unit.str_mods.find(0.75))
	elif find.name == "Slow": unit.agi_mods.remove(unit.agi_mods.find(0.75))
	elif find.name == "Frail": unit.def_mods.remove(unit.def_mods.find(0.75))
	elif find.name == "Dull": unit.int_mods.remove(unit.int_mods.find(0.75))

func add_status(value: Array) -> void:
	statuses.append(value)
	update_status()

func remove_status(value: String) -> void:
	for s in statuses:
		if s[0] == value:
			statuses.remove(statuses.find(s))
			emit_signal("show_text", "-" + value, pos)
			break
	update_status()

func update_status() -> void:
	status_ptr = 0
	delay = 0

func targetable(value: bool, display = true):
	if not enabled: return
	if not self.alive: value = false
	valid_target = value
	if valid_target:
		if display: target.show()
	else: target.hide()

func get_hit_and_crit_chance(hit) -> Array:
	var hit_roll = 100
	var crit_roll = 0
	if hit.stat_hit != Enums.StatType.NA:
		hit_roll = clamp(hit.item.hit_chance + float((hit.hit_chance) / float(get_stat(hit.stat_hit)) * 50 - 50), 0, 100)
#		hit_roll = clamp(hit.hit_chance / (get_stat(hit.stat_hit)), 0, 100)
		crit_roll = hit.crit_chance
	return [hit_roll, crit_roll]

func die():
	enabled = false
	emit_signal("died")

func set_hp_cur(value: int):
	hp_cur = int(clamp(value, 0, hp_max))
	hp_gauge.value = value
	if hp_cur <= 0: die()

func set_ap(value: int) -> void:
	ap = int(clamp(value, 0, 6))
	unit.ap = ap

func set_blocking(value: int) -> void:
	blocking = value
	self.hp_cur = hp_cur

func get_alive() -> bool:
	return hp_cur > 0

func get_melee_penalty() -> bool:
	return true

func has_perk(perk_name: String) -> bool:
	return unit.has_perk(perk_name)
