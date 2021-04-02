extends Resource
class_name Item

export var name: String
export(String, MULTILINE) var desc
export var frame: int
export var max_uses: int
export var uses: int
export(Enum.ItemType) var item_type
export(Enum.TargetType) var target_type
export(Enum.DamageType) var damage_type
export(Enum.StatType) var stat_used
export(Enum.StatType) var stat_vs
export var multiplier: float
export var bonus_damage: int
export var hits:= 1
export var hit_chance: int
export var crit_chance: int
export var sound_fx: String
export var added_effect: Resource
