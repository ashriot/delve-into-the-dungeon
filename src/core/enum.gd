extends Resource
class_name Enum

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
	TOME,
	TOOL
}

enum SubItemType {
	AXE,
	BOOMERANG,
	BOW,
	DAGGER,
	GUN,
	MACE,
	SHIELD,
	SPEAR,
	SWORD,
	WAND,
	AIR,
	ANCIENT,
	ARCANE,
	EARTH,
	FIRE,
	HEALING,
	WATER,
	WITCHCRAFT,
	CRAFT,
	DANCE,
	MARTIAL_ARTS,
	SORCERY,
	THIEVERY
	NA
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
	BLOCK
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
		TargetType.ANY_ALLY: return "an ally"
		TargetType.ANY_ROW: return "an enemy row"
		TargetType.BACK_ROW: return "the back enemy row"
		TargetType.FRONT_ROW: return "the front enemy row"
		TargetType.MYSELF: return "Self-only"
		TargetType.ONE_BACK: return "a back row enemy"
		TargetType.ONE_ENEMY: return "an enemy"
		TargetType.ONE_FRONT: return "a front row enemy"
	return ""
