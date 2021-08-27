extends Resource
class_name Action

export var name: String
export(String, MULTILINE) var description = "Deal {potency} {dmg} damage to {tgt}.\n{aim}"
export var tier: = 1
export var ap_cost: = 2
export(Enum.ItemType) var item_type
export(Enum.SubItemType) var sub_type
export var melee: bool
export(Enum.TargetType) var target_type
export(Enum.DamageType) var damage_type
export(Enum.StatType) var stat_used
export(Enum.StatType) var stat_vs
export(Enum.StatType) var stat_hit = Enum.StatType.NA
export var multiplier: float
export var bonus_damage: int
export var min_hits:= 1
export var max_hits:= 1
export var lifesteal: = 0.0
export var hit_chance: int
export var crit_chance: int
export var sound_fx: String
export var use_fx: String
export(Array, Array) var inflict_boons
export(Array, Array) var inflict_hexes
export(Array, Array) var gain_boons
export(Array, Array) var gain_hexes

var frame setget , get_frame
var desc setget , get_desc

func get_frame() -> int:
	var id = 0
	match item_type:
		Enum.ItemType.WEAPON:
			if sub_type == Enum.SubItemType.BOOMERANG: id += 1
			elif sub_type == Enum.SubItemType.BOW: id += 2
			elif sub_type == Enum.SubItemType.DAGGER: id += 3
			elif sub_type == Enum.SubItemType.GUN: id += 4
			elif sub_type == Enum.SubItemType.MACE: id += 5
			elif sub_type == Enum.SubItemType.SPEAR: id += 6
			elif sub_type == Enum.SubItemType.SHIELD: id += 7
			elif sub_type == Enum.SubItemType.SWORD: id += 8
			elif sub_type == Enum.SubItemType.WAND: id += 9
		Enum.ItemType.MARTIAL_SKILL:
			id += 20
		Enum.ItemType.SPECIAL_SKILL:
			id += 21
		Enum.ItemType.TOME:
			id += 10
		Enum.ItemType.TOOL:
			id += 12
	return id

func get_desc() -> String:
	var sub = description as String
	var dmg = Enum.get_stat_name(stat_used) + "x" + str(multiplier)
	var hits = str(max_hits) if min_hits == max_hits else (str(min_hits) + "-" + str(max_hits))
	dmg += ("(x" + hits + ")") if max_hits > 1 else ""
	sub = sub.replace("{potency}", dmg)
	sub = sub.replace("{dmg}", Enum.get_damage_name(damage_type))
	sub = sub.replace("{tgt}", Enum.get_target_name(target_type))
	sub = sub.replace("{aim}", "Hit: " + str(hit_chance) + "% | Crit: " + str(crit_chance) + "%" )
	sub = sub.replace("{vs}", "vs. " + Enum.get_stat_name(stat_vs) )
	return sub

func colorize(stat, text) -> String:
	var color = ""
	match stat:
		Enum.StatType.CurHP:
			color = "[color=#50c23a]"
		Enum.StatType.MaxHP:
			color = "[color=#50c23a]"
		Enum.StatType.STR:
			color = "[color=#cc6056]"
		Enum.StatType.AGI:
			color = "[color=#dbb642]"
		Enum.StatType.INT:
			color = "[color=#61c4da]"
		Enum.StatType.DEF:
			color = "[color=#b4b4ae]"
	return color + text + "[/color]"
