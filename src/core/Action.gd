extends Resource
class_name Action

export var name: String
export(String, MULTILINE) var description = "Deal {potency} {dmg} damage to {tgt}.\n{aim}"
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
export var hits:= 1
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
	var id = 70
	match item_type:
		Enum.ItemType.WEAPON:
			if sub_type == Enum.SubItemType.AXE: id += 10
			elif sub_type == Enum.SubItemType.BOOMERANG: id += 11
			elif sub_type == Enum.SubItemType.BOW: id += 12
			elif sub_type == Enum.SubItemType.DAGGER: id += 13
			elif sub_type == Enum.SubItemType.GUN: id += 14
			elif sub_type == Enum.SubItemType.MACE: id += 15
			elif sub_type == Enum.SubItemType.SPEAR: id += 16
			elif sub_type == Enum.SubItemType.SHIELD: id += 17
			elif sub_type == Enum.SubItemType.SWORD: id += 18
			elif sub_type == Enum.SubItemType.WAND: id += 19
		Enum.ItemType.MARTIAL_SKILL:
			id += 0
		Enum.ItemType.SPECIAL_SKILL:
			id += 1
		Enum.ItemType.TOME:
			if sub_type == Enum.SubItemType.AIR: id += 2
			elif sub_type == Enum.SubItemType.ANCIENT: id += 3
			elif sub_type == Enum.SubItemType.ARCANE: id += 4
			elif sub_type == Enum.SubItemType.EARTH: id += 5
			elif sub_type == Enum.SubItemType.FIRE: id += 6
			elif sub_type == Enum.SubItemType.HEALING: id += 7
			elif sub_type == Enum.SubItemType.WATER: id += 8
			elif sub_type == Enum.SubItemType.WITCHCRAFT: id += 9
		Enum.ItemType.TOOL:
			id -= 10
	return id

func get_desc() -> String:
	var sub = description as String
	var dmg = Enum.get_stat_name(stat_used) + "x" + str(multiplier)
	dmg += ("(x" + str(hits) + ")") if hits > 1 else ""
	dmg = colorize(stat_used, dmg)
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
			color = "[color=#ff50c23a]"
		Enum.StatType.MaxHP:
			color = "[color=#ff50c23a]"
		Enum.StatType.STR:
			color = "[color=#ffcc6056]"
		Enum.StatType.AGI:
			color = "[color=#ffdbb642]"
		Enum.StatType.INT:
			color = "[color=#ff61c4da]"
		Enum.StatType.DEF:
			color = "[color=#ffb4b4ae]"
	return color + text + "[/color]"
