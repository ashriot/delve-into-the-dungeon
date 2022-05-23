extends Control
class_name BattlePanel

signal done
signal died(panel)
signal show_dmg(text, pos, crit)
signal show_text(text, pos, display)
signal dmg_dealt(dmg, user, action, crit)

var arcanum = preload("res://resources/actions/skills/arcana/arcanum.tres")
var slay = preload("res://resources/effects/banes/slay.tres")

onready var button: = $Button
onready var hp_gauge: = $HpGauge
onready var ap_gauge = $ApGauge
onready var target: = $Target
onready var sprite: = $Sprite
onready var anim: = $AnimationPlayer

onready var status = $Status

var enabled: bool
var alive: bool setget, get_alive
var crit_round: bool
var unit: Unit = null
var hp_cur: int setget set_hp_cur
var hp_max: int
var hp_percent: float setget, get_hp_percent
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
var hasted: bool setget, get_hasted

func init(battle) -> void:
	anim.playback_speed = 1 / GameManager.spd
	pos = rect_global_position
	pos.x -= 23
	pos.y += rect_size.y / 2
# warning-ignore:return_value_discarded
	connect("show_dmg", battle, "show_dmg_text")
# warning-ignore:return_value_discarded
	connect("show_text", battle, "show_text")
	connect("dmg_dealt", battle, "dmg_dealt")

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

func take_hit(hit: Hit) -> bool:
	var gained_xp = false
	var item = hit.action as Action
	var effect_only = item.damage_type == Enums.DamageType.EFFECT_ONLY
	var fx = item.sound_fx
	var lifesteal = hit.action.lifesteal
	var miss = false
	var crit = false
	var hit_roll = randi() % 100 + 1
	var crit_roll = randi() % 100 + 1
	if hit_roll > hit.hit_chance: miss = true
	elif crit_roll <= hit.crit_chance:
		crit = true
		hit.panel.just_crit()
	var multi = item.multiplier
	var dmg = hit.dmg if not crit else hit.crit_dmg
	print(hit.panel.unit.name, " uses ", hit.action.name, " -> Base ATK: ", hit.atk, " x ", hit.action.multiplier, " x ", (hit.dmg_mod * 100), "% = ", hit.dmg)
	var lifesteal_heal = int(float(min(dmg, hp_cur)) * lifesteal)
	print(" -> Hit: ", hit_roll, " < ", hit.hit_chance, "? ", ("Miss..." if miss else "Hit!!"), " Crit: ", crit_roll, " < ", hit.crit_chance, "% ", crit) 
	print(unit.name, " -> Base DEF: ", unit.get_stat(item.stat_vs), " DEF: ", float(hit.def / 2) * hit.action.multiplier, " DMG: ", dmg)
	var dmg_text = ""
	var blocked = 0
	if not miss and !effect_only:
		if blocking > 0:
			if blocking >= dmg:
				self.blocking -= dmg
				blocked = dmg
				dmg = 0
			else:
				dmg -= blocking
				blocked = blocking
				self.blocking = 0
		if dmg > 0: gained_xp = true
		if item.damage_type == Enums.DamageType.MARTIAL:
			if has_boon("Aegis"):
				remove_boon(get_boon("Aegis"))
				dmg = int(0.5 * dmg)
		if item.damage_type != Enums.DamageType.MARTIAL:
			if has_boon("Barrier"):
				remove_boon(get_boon("Barrier"))
				dmg = int(0.5 * dmg)
		self.hp_cur -= dmg
		dmg_text = str(dmg) + ("!" if crit else "")
		if blocked: dmg_text += "{" + str(blocked) + "}"
		anim.play("Hit")
		emit_signal("dmg_dealt", dmg, hit.panel, hit.action, crit)
	elif miss:
		dmg_text = "Miss"
		fx = "miss"
		if hit.panel.has_bane("Blind"):
			hit.panel.remove_bane(hit.panel.get_bane("Blind"))
	emit_signal("show_dmg", dmg_text, pos, crit)
	if hit.target_type >= Enums.TargetType.ONE_ENEMY \
		and hit.target_type <= Enums.TargetType.ONE_BACK \
		or hit.target_type == Enums.TargetType.RANDOM_ENEMY:
		AudioController.play_sfx(fx)
	if has_bane("Sleep"):
		remove_bane(get_bane("Sleep"))
	if lifesteal_heal > 0:
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
		hit.panel.take_healing(lifesteal_heal)
	if item.name == "Freeze Ray":
		if not has_bane("Slow"): return gained_xp
		else: remove_bane(get_bane("Slow"))
	if item.name == "Disintegrate":
		if hp_cur <= hit.panel.unit.intellect * 3:
			yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
			emit_signal("show_text", "+" + slay.name, pos)
			gain_bane(slay, 1)
	elif item.name == "Death Dance":
		if hp_cur <= hit.panel.unit.agility * 1:
			yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
			emit_signal("show_text", "+" + slay.name, pos)
			gain_bane(slay, 1)
	if item.inflict_banes.size() > 0 and not miss and self.alive:
		if not effect_only: yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
		var banes = item.inflict_banes
		if item.name == "Banish":
			if hp_cur <= hit.panel.unit.intellect * 2:
				banes[0][2] = 100
		for bane in banes:
			var chance = bane[2]
			if item.name == "Hypnotize":
				chance *= hit.dmg_mod
				print("Hypno chance: ", chance)
			if item.sub_type == Enums.SubItemType.KNIFE and hit.panel.unit.job == "Thief":
				chance = 100
			if randi() % 100 + 1 > chance: # resisted
				if effect_only:
					emit_signal("show_text", "Resist", pos)
				continue
			var success = gain_bane(bane[0], bane[1])
			if success:
				emit_signal("show_text", "+" + bane[0].name, pos)
				gained_xp = true
			yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
		if not item.gain_boons:
			yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	if item.gain_boons and not miss:
		for boon in item.gain_boons:
			if randi() % 100 + 1 > boon[2]: continue
			if not effect_only: yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
			var success = hit.panel.gain_boon(boon[0], boon[1])
			if success: emit_signal("show_text", "+" + boon[0].name, hit.panel.pos)
			yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
		yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
	return gained_xp

func take_friendly_hit(user: BattlePanel, item: Action) -> void:
	if item.name == "Draw Arcana":
		user.unit.job_data["arcana"] = 0
		for i in range(5, 10):
			user.unit.items[i] = arcanum
	var dmg = int(item.multiplier * user.get_stat(item.stat_used) + item.bonus_damage)
	var def = int(get_stat(item.stat_vs) * item.multiplier) if item.stat_vs != Enums.StatType.NA else 0
	var dmg_mod = 1.0
	if item.name == "Healing Haka":
		def = int(float(hp_max - hp_cur) * 0.5)
	var dmg_text = ""
	if item.sub_type == Enums.SubItemType.SORCERY:
		dmg_mod += user.unit.job_data["sp_cur"] * 0.34
		user.unit.job_data["sp_cur"] = 0
	if item.damage_type == Enums.DamageType.HEAL:
		dmg += def
		dmg = int(dmg * dmg_mod)
		self.hp_cur += dmg
		dmg_text = str(dmg)
	elif item.damage_type == Enums.DamageType.BLOCK:
		dmg = int(dmg * dmg_mod)
		dmg_text = str(dmg)
		self.blocking = max(blocking, dmg)
	if dmg > 0:
		emit_signal("show_text", "+" + dmg_text, pos)
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	if item.grant_ap != 0:
		emit_signal("show_text", "+" + str(item.grant_ap) + "AP", pos)
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
	if amt != 0: emit_signal("show_dmg", str(amt), pos, false)

func just_crit() -> void:
	if not crit_round and has_perk("Critical Grace"):
		self.ap += 1
		emit_signal("show_text", "+1AP", pos)
		crit_round = true

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
			else: unit.int_mods.append(0.8)
		elif bane.name == "Frail":
			if has_boon("Safe"):
				remove_boon(get_boon("Safe"))
				applied = false
			else: unit.def_mods.append(0.8)
		elif bane.name == "Slow":
			if has_boon("Fast"):
				remove_boon(get_boon("Fast"))
				applied = false
			else: unit.agi_mods.append(0.8)
		elif bane.name == "Weak":
			if has_boon("Bold"):
				remove_boon(get_boon("Bold"))
				applied = false
			else: unit.str_mods.append(0.8)
		elif bane.name == "Slay":
			self.hp_cur = 0
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
			else: unit.str_mods.append(1.2)
		elif boon.name == "Fast":
			if has_bane("Slow"):
				remove_bane(get_bane("Slow"))
				applied = false
			else: unit.agi_mods.append(1.2)
		elif boon.name == "Safe":
			if has_bane("Frail"):
				remove_bane(get_bane("Frail"))
				applied = false
			else: unit.def_mods.append(1.2)
		elif boon.name == "Wise":
			if has_bane("Dull"):
				remove_bane(get_bane("Dull"))
				applied = false
			else: unit.int_mods.append(1.2)
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
				if boon[0].triggered:
					trigger_boon(boon[0].name)
					yield(get_tree().create_timer(0.25, true), "timeout")
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
					yield(get_tree().create_timer(0.33, true), "timeout")
				if bane[1] == 0:
					remove_bane(bane[0])
	call_deferred("emit_signal", "done")

func trigger_boon(boon_name: String) -> void:
	if boon_name == "Mend":
		take_healing(int(float(hp_max) * 0.1))
		yield(get_tree().create_timer(0.15, true), "timeout")
	if boon_name == "Shield":
		self.blocking = (int(float(unit.get_highest())))
		yield(get_tree().create_timer(0.15, true), "timeout")
	if boon_name == "Haste":
		self.ap += 1
		if (randi() % 100) < 25: remove_boon(get_boon("Haste"))
		yield(get_tree().create_timer(0.15, true), "timeout")

func trigger_bane(bane_name: String) -> void:
	if bane_name == "Bleed":
		take_damage(int(float(hp_max) * 0.1))
		yield(get_tree().create_timer(0.15, true), "timeout")
	if bane_name == "Burn":
		take_damage(unit.get_highest() * 0.5)
		yield(get_tree().create_timer(0.15, true), "timeout")
	if bane_name == "Poison":
		take_damage(max(int(float(hp_cur) * 0.2), 1))
		yield(get_tree().create_timer(0.15, true), "timeout")
	if bane_name == "Sleep":
		emit_signal("show_text", "Asleep", pos)

func remove_boon(find: Effect) -> void:
	for boon in boons:
		if boon[0] == find:
			boons.remove(boons.find(boon))
			break
	for s in statuses:
		if s[0] == find.name:
			remove_status(find.name)
			break

func remove_bane(find: Effect) -> void:
	for bane in banes:
		if bane[0] == find:
			banes.remove(banes.find(bane))
			break
	for s in statuses:
		if s[0] == find.name:
			remove_status(find.name)
			break
	if find.name == "Weak": unit.str_mods.remove(unit.str_mods.find(0.8))
	elif find.name == "Slow": unit.agi_mods.remove(unit.agi_mods.find(0.8))
	elif find.name == "Frail": unit.def_mods.remove(unit.def_mods.find(0.8))
	elif find.name == "Dull": unit.int_mods.remove(unit.int_mods.find(0.8))

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
	if hit.action.stat_hit != Enums.StatType.NA:
		hit_roll = clamp(float((hit.hit_chance) / float(get_stat(hit.action.stat_hit)) * 50 - 50), 0, 100)
	var crit_roll = hit.crit_chance if hit.can_crit else 0
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

func get_hp_percent() -> float:
	return float(hp_cur) / hp_max

func set_blocking(value: int) -> void:
	blocking = value
	self.hp_cur = hp_cur

func get_alive() -> bool:
	return hp_cur > 0

func get_melee_penalty() -> bool:
	return true

func has_perk(perk_name: String) -> bool:
	return unit.has_perk(perk_name)

func get_perk(perk_name: String) -> int:
	return unit.get_perk(perk_name)

func get_hasted() -> bool:
	return self.has_boon("Haste")
