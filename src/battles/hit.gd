extends Resource

class_name Hit

var action: Resource
var hit_chance: int
var crit_chance: int
var dmg_mod := 0.0
var atk := 0
var level := 0
var panel = null
var target = null
var split: int
var can_crit := false
var user_pos: Vector2
var melee_penalty: bool
var target_type: int
var targets: int

var dmg: int
var crit_dmg: int
var def: int
var def_mod: int
var bonus_dmg: int

func init(_action, _panel, _split, _target = null):
	action = _action as Action
	panel = _panel
	split = _split
	user_pos = panel.pos
	can_crit = can_crit()
	level = panel.unit.level if panel.unit is Enemy else 0
	bonus_dmg = action.bonus_damage
	target_type = action.target_type
	if "Siphon" in action.name: target_type += max((panel.unit.job_data["sp_cur"] - 1), 0) * 3

	melee_penalty = action.melee and panel.melee_penalty
	if _target: update_target_data(_target)

func can_crit() -> bool:
	if action.stat_hit != Enums.StatType.NA:
		return true
	elif panel.has_perk("Wild Sorcery") \
	and action.sub_type == Enums.SubItemType.SORCERY:
		return true
	return false

func update_target_data(_target) -> void:
	if not _target: return
	target = _target
	atk = panel.get_stat(action.stat_used)
	hit_chance = 100
	crit_chance = action.crit_chance + panel.unit.crit_chance
	var target_type = action.target_type
	if panel.unit is Player and panel.unit.job:
		if (panel.unit.job == "Thief" \
		and action.sub_type == Enums.SubItemType.KNIFE):
			melee_penalty = false
	if action.stat_hit == Enums.StatType.AGI:
		var base_hit = panel.unit.agility + (panel.get_perk("Precise") * 10)
		hit_chance = clamp(action.hit_chance + float((base_hit) / (float(target.get_stat(action.stat_hit))) * 50) - 60, 0, 100)
		if panel.has_boon("Aim"):
			hit_chance = 100
			crit_chance += 25
		elif panel.has_bane("Blind"):
			hit_chance /= 2
			crit_chance = 0
	if not can_crit: crit_chance = 0
	if action.name == "Rapier":
		var strength = panel.get_stat(Enums.StatType.STR)
		var agility = panel.get_stat(Enums.StatType.AGI)
		atk = max(strength, agility)
	if panel.has_perk("Magic Weapon") and action.sub_type != Enums.SubItemType.WAND:
		atk += int(panel.unit.intellect * (panel.get_perk("Magic Weapon") * 0.05))
	if action.sub_type == Enums.SubItemType.SWORD and panel.has_perk("Sword Mastery"):
		atk += int(panel.unit.agility * (panel.get_perk("Sword Mastery") * 0.05))
	dmg_mod = 1.0
	if melee_penalty: dmg_mod -= 0.50
	if panel.has_boon("Brave"):
		dmg_mod += 0.5
	if target.has_bane("Fear"):
		dmg_mod += 0.5
	if action.name == "Caladbolg":
		dmg_mod += panel.hp_percent
	elif action.name == "Drown":
		dmg_mod += (0.5 - target.hp_percent / 2)
	elif action.name == "Fireball":
		if target.has_bane("Burn"):
			dmg_mod += 0.5
	elif action.name == "Hex Bolt":
		dmg_mod += 0.25 * target.banes.size()
	if action.sub_type == Enums.SubItemType.SORCERY:
		if action.name == "Mana Darts":
			action.min_hits = 1 + panel.unit.job_data["sp_cur"]
			action.max_hits = 1 + panel.unit.job_data["sp_cur"]
		else:
			dmg_mod += panel.unit.job_data["sp_cur"] * 0.34
	dmg = float((action.multiplier * (atk)) + bonus_dmg)
	crit_dmg = dmg + float(panel.get_stat(Enums.StatType.POW)) * action.multiplier
	def = target.get_stat(action.stat_vs)
	def_mod = int(float(def * 0.5) * action.multiplier)
	var def = target.get_stat(action.stat_vs)
	var def_mod = float(def * 0.5) * action.multiplier
	dmg = max(int((dmg * dmg_mod) - def_mod), 0)
	crit_dmg = max(int((crit_dmg * dmg_mod) - def_mod), 0)
	dmg /= split
	crit_dmg /= split
