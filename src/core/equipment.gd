extends Resource
class_name Equipment

export var name: String
export(String, MULTILINE) var description
export var tier := 1
export var weight := 0

export var hp_bonus := 0
export var str_bonus := 0
export var agi_bonus := 0
export var int_bonus := 0
export var def_bonus := 0

export(Enum.EquipmentType) var equipment_type
