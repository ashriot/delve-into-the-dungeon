extends Resource
class_name Action

export var name: String
export(String, MULTILINE) var desc
export var frame: int
export var uses: int
export(Enum.ActionType) var action_type
export(Enum.TargetType) var target_type
export(Enum.DamageType) var damage_type
export(Enum.StatType) var stat_used
export(Enum.StatType) var stat_vs
export var multiplier: float
export var bonus_damage: int
export var hits:= 1
export var sound_fx: String
export var added_effect: Resource
