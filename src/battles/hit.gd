extends Resource

class_name Hit

var item: Resource
var hit_chance: int
var crit_chance: int
var bonus_dmg: int
var dmg_mod: float
var atk: int
var stat_hit: int
var level: int
var user = null
var split: int
var user_pos: Vector2

func init(_item, _hit_chance, _crit_chance, _bonus_dmg, _dmg_mod, _atk, _user, _split = 1):
	item = _item as Action
	hit_chance = _hit_chance
	print("New Hit Chance: ", hit_chance)
	crit_chance = _crit_chance
	bonus_dmg = _bonus_dmg + item.bonus_damage
	dmg_mod = _dmg_mod
	atk = _atk
	stat_hit = item.stat_hit
	user = _user
	user_pos = user.pos
	split = _split
	if user.unit is Enemy: level = user.unit.level
	else: level = 0
