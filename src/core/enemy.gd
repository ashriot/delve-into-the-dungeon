extends Unit
class_name Enemy

export(String, MULTILINE) var desc
export var level:= 1
export var gold: int
export(Array, Resource) var actions

var hp_growth: int
var str_growth: int
var agi_growth: int
var int_growth: int
var def_growth: int

func get_strength() -> int:
	var str_mod = 1.0
	for mod in str_mods:
		str_mod *= mod
	return (strength + str_bonus + str_growth) * (str_mod)
	print(name, " STR mod: ", str_mod)

func get_agility() -> int:
	var agi_mod = 1.0
	for mod in agi_mods:
		agi_mod *= mod
	return (agility + agi_bonus + agi_growth) * (agi_mod)
	print(name, " AGI mod: ", agi_mod)

func get_intellect() -> int:
	var int_mod = 1.0
	for mod in int_mods:
		int_mod *= mod
	return (intellect + int_bonus + int_growth) * (int_mod)
	print(name, " INT mod: ", int_mod)

func get_defense() -> int:
	var def_mod = 1.0
	for mod in def_mods:
		def_mod *= mod
	return (defense + def_bonus + def_growth) * (def_mod)
	print(name, " DEF mod: ", def_mod)

func get_hp_max() -> int:
	return hp_max + hp_growth
