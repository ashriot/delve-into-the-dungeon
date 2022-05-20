extends Resource
class_name Unit

export var name: String
export var frame: int

export var hp_cur: int

export var hp_max: int setget, get_hp_max
export var hp_percent: float setget, get_hp_percent
export var hp_missing: int setget, get_hp_missing
export var ap: int
export var strength: int setget, get_strength
export var agility: int setget, get_agility
export var intellect: int setget, get_intellect
export var defense: int setget, get_defense
export var crit_chance: int setget, get_crit_chance
export var crit_power: int setget, get_crit_power

export var hp_bonus: int
export var str_bonus: int
export var agi_bonus: int
export var int_bonus: int
export var def_bonus: int
export var crit_bonus: int
export var power_bonus: int

export(Array, float) var hp_mods
export(Array, float) var str_mods
export(Array, float) var agi_mods
export(Array, float) var int_mods
export(Array, float) var def_mods

export(Dictionary) var perks

func heal(amt := 9999) -> void:
	# warning-ignore:narrowing_conversion
	hp_cur = clamp(hp_cur + amt, 0, self.hp_max)

func get_highest() -> int:
	var highest = self.strength
	if highest < self.agility:
		highest = self.agility
	if highest < self.intellect:
		highest = self.intellect
	return highest

func get_hp_max() -> int:
	var hp_mod = 1.0
	for mod in hp_mods:
		hp_mod *= mod
	return int((hp_max + hp_bonus) * (hp_mod))

func get_hp_percent() -> float:
	if self.hp_max < 1: return 0.0
	return float(self.hp_cur) / self.hp_max

func get_hp_missing() -> int:
	return hp_max - hp_cur

func get_strength() -> int:
	var str_mod = 1.0
	for mod in str_mods:
		str_mod *= mod
	return int((strength + str_bonus) * (str_mod))

func get_agility() -> int:
	var agi_mod = 1.0
	for mod in agi_mods:
		agi_mod *= mod
	return int((agility + agi_bonus) * (agi_mod))

func get_intellect() -> int:
	var int_mod = 1.0
	for mod in int_mods:
		int_mod *= mod
	return int((intellect + int_bonus) * (int_mod))

func get_defense() -> int:
	var def_mod = 1.0
	for mod in def_mods:
		def_mod *= mod
	return int((defense + def_bonus) * (def_mod))

func get_crit_chance() -> int:
	return crit_chance + crit_bonus

func get_crit_power() -> int:
	var total = 0
	total += power_bonus
	total += float(self.strength) * 0.5
	total += float(self.strength) * (get_perk("Heavy Criticals") * 0.05)
	total += float(self.agility) * (get_perk("Precise Criticals") * 0.1)
	total += float(self.intellect) * (get_perk("Focused Criticals") * 0.05)
	return int(total)

func base_hp_max() -> int:
	return hp_max

func base_str() -> int:
	return strength

func base_agi() -> int:
	return agility

func base_int() -> int:
	return intellect

func base_def() -> int:
	return defense

func get_stat(stat) -> int:
	match stat:
		Enums.StatType.CurHP: return self.hp_cur
		Enums.StatType.MaxHP: return self.hp_max
		Enums.StatType.MissHP: return self.hp_missing
		Enums.StatType.STR: return self.strength
		Enums.StatType.AGI: return self.agility
		Enums.StatType.INT: return self.intellect
		Enums.StatType.DEF: return self.defense
		Enums.StatType.CRIT: return self.crit_chance
		Enums.StatType.POW: return self.crit_power
		Enums.StatType.NA: return 0
	return -999

func get_base_stat(stat) -> int:
	match stat:
		Enums.StatType.CurHP: return hp_cur
		Enums.StatType.MaxHP: return hp_max
		Enums.StatType.MissHP: return hp_max
		Enums.StatType.STR: return strength
		Enums.StatType.AGI: return agility
		Enums.StatType.INT: return intellect
		Enums.StatType.DEF: return defense
		Enums.StatType.CRIT: return crit_chance
		Enums.StatType.POW: return crit_power
		Enums.StatType.NA: return 0
	return -999

func increase_base_stat(stat, amt: int) -> void:
	match stat:
		Enums.StatType.MaxHP:
			hp_max += amt
			return
		Enums.StatType.STR:
			strength += amt
			return
		Enums.StatType.AGI:
			agility += amt
			return
		Enums.StatType.INT:
			intellect += amt
			return
		Enums.StatType.DEF:
			defense += amt
			return

func has_perk(perk_name) -> bool:
	for i in perks.size():
		if perks[i] == null: continue
		if perks[i].name == perk_name:
			return true
	return false

func get_perk(perk_name) -> int:
	for i in perks.size():
		if not perks[i]: continue
		elif perks[i].name == perk_name:
			return perks[i].rank
	return 0
