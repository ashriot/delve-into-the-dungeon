extends Resource
class_name Equipment

export var name: String
export(String, MULTILINE) var description
export var quality := 1
export var rank := 0

export var hp_bonus := 0
export var str_bonus := 0
export var agi_bonus := 0
export var int_bonus := 0
export var def_bonus := 0

export(Enums.EquipmentType) var equipment_type

var frame: int setget , get_frame

func get_frame() -> int:
	if equipment_type == Enums.EquipmentType.HEAD: return 30
	if equipment_type == Enums.EquipmentType.BODY: return 31
	if equipment_type == Enums.EquipmentType.HANDS: return 32
	if equipment_type == Enums.EquipmentType.FEET: return 33
	return 34
