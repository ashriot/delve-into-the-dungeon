extends Resource

class_name Hit

var item: Resource
var hit_chance: int
var crit_chance: int
var bonus_dmg: int
var dmg_mod: float
var atk: int

func init(_item, _hit_chance, _crit_chance, _bonus_dmg, _dmg_mod, _atk):
	item = _item
	hit_chance = _hit_chance
	crit_chance = _crit_chance
	bonus_dmg = _bonus_dmg
	dmg_mod = _dmg_mod
	atk = _atk
