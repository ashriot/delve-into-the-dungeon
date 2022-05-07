class_name Enums

const default_color := Color("#f0eae3")
const yellow_color := Color("#4d9be6")
const gray_color := Color("#7d7071")
const block_color := Color("#9babb2")
const black_color := Color("#202020")
const off_white := Color("#ffffeb")
const quick_color := Color("#c32454")
const ap_color := Color("f79617")

const worn := Color("#a0938e")
const common := Color("#f0eae3")
const fine := Color("#71aa34")
const exquisite := Color("#3978a8")
const masterwork := Color("#8e478c")
const artefact := Color("#e6482e")

enum StatType {
	CurHP,
	MaxHP,
	STR,
	AGI,
	INT,
	DEF,
	NA
}

enum ItemType {
	WEAPON,
	MARTIAL_SKILL,
	SPECIAL_SKILL,
	SCROLL,
	STAFF,
	TOME,
	TOOL
}

enum SubItemType {
	AXE,		#0
	BOOMERANG,
	BOW,
	KNIFE,
	GUN,
	MACE,		#5
	SHIELD,
	SPEAR,
	SWORD,
	WAND,
	AIR,		#10
	ANCIENT,
	EARTH,
	FIRE,
	WATER,
	ABJURATION,	#15
	ENCHANTMENT,
	DIVINE,
	RESTORATION,
	JINX,
	NECROMANCY,	#20
	FORBIDDEN,
	ARCANA,
	DANCE,
	MARTIAL_ARTS,
	PERFORM,	#25
	SORCERY,
	TOOL,		#27
	NA
}

enum EquipmentType {
	HEAD,
	BODY,
	HANDS,
	FEET,
	TRINKET
}

enum TargetType {
	MYSELF,
	ANY_ALLY,
	OTHER_ALLY,
	OTHER_ALLIES_ONLY,
	ALL_ALLIES,
	RANDOM_ALLY,
	ONE_ENEMY,
	ONE_FRONT,
	ONE_BACK,
	ANY_ROW,
	FRONT_ROW,
	BACK_ROW,
	ALL_ENEMIES,
	RANDOM_ENEMY,
	RANDOM_ANYONE
}

enum DamageType {
	MARTIAL,
	AIR,
	EARTH,
	FIRE,
	WATER,
	PURE,
	HEAL,
	EFFECT_ONLY,
	BLOCK,
	AP
}

static func get_stat_name(stat) -> String:
	match stat:
		StatType.CurHP: return "Current HP"
		StatType.MaxHP: return "Max HP"
		StatType.STR: return "STR"
		StatType.AGI: return "AGI"
		StatType.INT: return "INT"
		StatType.DEF: return "DEF"
	return ""

static func get_damage_name(damage) -> String:
	match damage:
		DamageType.MARTIAL: return "Martial"
		DamageType.AIR: return "Air"
		DamageType.EARTH: return "Earth"
		DamageType.FIRE: return "Fire"
		DamageType.WATER: return "Water"
		DamageType.PURE: return "Pure"
	return ""

static func get_target_name(target) -> String:
	match target:
		TargetType.ALL_ALLIES: return "the party"
		TargetType.ALL_ENEMIES: return "the enemy party"
		TargetType.RANDOM_ENEMY: return "a random enemy"
		TargetType.ANY_ALLY: return "an ally"
		TargetType.ANY_ROW: return "an enemy row"
		TargetType.BACK_ROW: return "the back enemy row"
		TargetType.FRONT_ROW: return "the front enemy row"
		TargetType.MYSELF: return "Self-only"
		TargetType.ONE_BACK: return "a back row enemy"
		TargetType.ONE_ENEMY: return "an enemy"
		TargetType.ONE_FRONT: return "a front row enemy"
	return ""
