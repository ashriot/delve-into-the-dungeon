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

func base_hp_max() -> int:
	return hp_max

func get_strength() -> int:
	return (strength + str_bonus + str_growth) * (1 + str_mod)

func get_agility() -> int:
	return (agility + agi_bonus + agi_growth) * (1 + agi_mod)

func get_intellect() -> int:
	return (intellect + int_bonus + int_growth) * (1 + int_mod)

func get_defense() -> int:
	return (defense + def_bonus + def_growth) * (1 + def_mod)


func get_hp_max() -> int:
	return hp_max + hp_growth
