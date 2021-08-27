extends Unit
class_name Enemy

export(String, MULTILINE) var desc
export var level:= 1
export var ap_init: int
export var gold: int
export(Dictionary) var actions

var hp_growth: int
var str_growth: int
var agi_growth: int
var int_growth: int
var def_growth: int

func get_strength() -> int:
	var str_mod = 1.0
	for mod in str_mods:
		str_mod *= mod
	return int((strength + str_bonus + str_growth) * (str_mod))

func get_agility() -> int:
	var agi_mod = 1.0
	for mod in agi_mods:
		agi_mod *= mod
	return int((agility + agi_bonus + agi_growth) * (agi_mod))

func get_intellect() -> int:
	var int_mod = 1.0
	for mod in int_mods:
		int_mod *= mod
	return int((intellect + int_bonus + int_growth) * (int_mod))

func get_defense() -> int:
	var def_mod = 1.0
	for mod in def_mods:
		def_mod *= mod
	return int((defense + def_bonus + def_growth) * (def_mod))

func get_hp_max() -> int:
	return hp_max + hp_growth
