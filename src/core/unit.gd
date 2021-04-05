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

export var str_mod: int
export var agi_mod: int
export var int_mod: int
export var def_mod: int

func get_strength() -> int:
	return (strength + str_bonus) * (1 + str_mod)

func get_agility() -> int:
	return (agility + agi_bonus) * (1 + agi_mod)

func get_intellect() -> int:
	return (intellect + int_bonus) * (1 + int_mod)

func get_defense() -> int:
	return (defense + def_bonus) * (1 + def_mod)

func base_str() -> int:
	return strength

func base_agi() -> int:
	return agility

func base_int() -> int:
	return intellect

func base_def() -> int:
	return defense

func get_stat(stat) -> int:
	if stat == Enum.StatType.STR: return self.strength
	elif stat == Enum.StatType.AGI: return self.agility
	elif stat == Enum.StatType.INT: return self.intellect
	elif stat == Enum.StatType.DEF: return self.defense
	elif stat == Enum.StatType.NA: return 0
	else: return -999

func get_hp_max() -> int:
	return hp_max
