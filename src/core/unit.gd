extends Resource
class_name Unit

export var name: String
export var frame: int

export var hp_max: int setget, get_hp_max
export var hp_cur: int

export var strength: int setget, get_strength
export var agility: int setget, get_agility
export var intellect: int setget, get_intellect
export var defense: int setget, get_defense

export var str_bonus: int
export var agi_bonus: int
export var int_bonus: int
export var def_bonus: int

export(Array, float) var str_mods
export(Array, float) var agi_mods
export(Array, float) var int_mods
export(Array, float) var def_mods

export(Dictionary) var perks

func get_strength() -> int:
	var str_mod = 1.0
	for mod in str_mods:
		str_mod *= mod
	return (strength + str_bonus) * (str_mod)

func get_agility() -> int:
	var agi_mod = 1.0
	for mod in agi_mods:
		agi_mod *= mod
	return (agility + agi_bonus) * (agi_mod)

func get_intellect() -> int:
	var int_mod = 1.0
	for mod in int_mods:
		int_mod *= mod
	return (intellect + int_bonus) * (int_mod)

func get_defense() -> int:
	var def_mod = 1.0
	for mod in def_mods:
		def_mod *= mod
	return (defense + def_bonus) * (def_mod)

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
	if stat == Enum.StatType.HP: return self.hp_cur
	elif stat == Enum.StatType.STR: return self.strength
	elif stat == Enum.StatType.AGI: return self.agility
	elif stat == Enum.StatType.INT: return self.intellect
	elif stat == Enum.StatType.DEF: return self.defense
	elif stat == Enum.StatType.NA: return 0
	else: return -999

func get_hp_max() -> int:
	return hp_max

func has_perk(perk_name) -> bool:
	for i in perks.size():
		if perks[i] == null: continue
		if perks[i].name == perk_name:
			return true
	return false
