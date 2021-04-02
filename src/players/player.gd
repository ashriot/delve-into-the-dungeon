extends Resource
class_name Player

signal player_changed

export var name: String
export var job: String
export var frame: int
export var slot: int

export var hp_max: int
export var hp_cur: int

export var strength: int
export var agility: int
export var intellect: int
export var defense: int

export var str_bonus: int
export var agi_bonus: int
export var int_bonus: int
export var def_bonus: int

export var str_mod: int
export var agi_mod: int
export var int_mod: int
export var def_mod: int

export(Array, Resource) var items

func changed():
	emit_signal("player_changed", self)

func get_stat(stat) -> int:
	if stat == Enum.StatType.AGI: return agility
	elif stat == Enum.StatType.DEF: return defense
	elif stat == Enum.StatType.INT: return intellect
	elif stat == Enum.StatType.STR: return strength
	return -999
