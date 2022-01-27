extends Resource
class_name Action

export var name: String
export(String, MULTILINE) var description = "Deal {potency} {dmg} damage to {tgt}.\n{aim}"
export var tier: = 1
export var ap_cost: = 2
export(Enums.ItemType) var item_type
export(Enums.SubItemType) var sub_type
export var melee: bool
export(Enums.TargetType) var target_type
export(Enums.DamageType) var damage_type
export(Enums.StatType) var stat_used
export(Enums.StatType) var stat_vs
export(Enums.StatType) var stat_hit = Enums.StatType.NA
export var multiplier: float
export var bonus_damage: int
export var min_hits:= 1
export var max_hits:= 1
export var split:= false
export var lifesteal: = 0.0
export var hit_chance: int
export var crit_chance: int
export var sound_fx: String
export var use_fx: String
export(Array, Array) var inflict_boons
export(Array, Array) var inflict_banes
export(Array, Array) var gain_boons
export(Array, Array) var gain_banes

var frame setget , get_frame
var desc setget , get_desc

func get_frame() -> int:
	var id = 0
	match item_type:
		Enums.ItemType.WEAPON:
			if sub_type == Enums.SubItemType.BOOMERANG: id += 1
			elif sub_type == Enums.SubItemType.BOW: id += 2
			elif sub_type == Enums.SubItemType.DAGGER: id += 3
			elif sub_type == Enums.SubItemType.GUN: id += 4
			elif sub_type == Enums.SubItemType.MACE: id += 5
			elif sub_type == Enums.SubItemType.SPEAR: id += 6
			elif sub_type == Enums.SubItemType.SHIELD: id += 7
			elif sub_type == Enums.SubItemType.SWORD: id += 8
			elif sub_type == Enums.SubItemType.WAND: id += 9
		Enums.ItemType.MARTIAL_SKILL:
			id = 20
		Enums.ItemType.SPECIAL_SKILL:
			id = 21
		Enums.ItemType.SCROLL:
			id = 10
		Enums.ItemType.STAFF:
			id = 11
		Enums.ItemType.TOME:
			id = 12
		Enums.ItemType.TOOL:
			id = 13
	return id

func get_desc() -> String:
	var sub = description as String
	var dmg = Enums.get_stat_name(stat_used) + "*" + str(multiplier)
	var hits = str(max_hits) if min_hits == max_hits else (str(min_hits) + "-" + str(max_hits))
	dmg += ("(*" + hits + ")") if max_hits > 1 else ""
	sub = sub.replace("{potency}", dmg)
	sub = sub.replace("{dmg}", Enums.get_damage_name(damage_type))
	sub = sub.replace("{tgt}", Enums.get_target_name(target_type))
	sub = sub.replace("{aim}", "Hit: " + str(hit_chance) + "% | Crit: " + str(crit_chance) + "%" )
	sub = sub.replace("{vs}", "vs. " + Enums.get_stat_name(stat_vs) )
	return sub

func colorize(stat, text) -> String:
	var color = ""
	match stat:
		Enums.StatType.CurHP:
			color = "[color=#50c23a]"
		Enums.StatType.MaxHP:
			color = "[color=#50c23a]"
		Enums.StatType.STR:
			color = "[color=#cc6056]"
		Enums.StatType.AGI:
			color = "[color=#dbb642]"
		Enums.StatType.INT:
			color = "[color=#61c4da]"
		Enums.StatType.DEF:
			color = "[color=#b4b4ae]"
	return color + text + "[/color]"
