extends Resource
class_name Action

export var name: String
export(String, MULTILINE) var desc
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
