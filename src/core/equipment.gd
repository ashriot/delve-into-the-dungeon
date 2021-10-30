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

export(Array, Resource) var perks

var frame: int setget , get_frame

func get_frame() -> int:
	if equipment_type == Enums.EquipmentType.HEAD: return 30
	if equipment_type == Enums.EquipmentType.BODY: return 31
	if equipment_type == Enums.EquipmentType.HANDS: return 32
	if equipment_type == Enums.EquipmentType.FEET: return 33
	return 34

func get_name() -> String:
	return name + "+" + str(rank) if rank > 0 else name

func get_desc() -> String:
	var text := "\n\n"
	if hp_bonus > 0: text += "HP+" + str(hp_bonus)
	if str_bonus > 0:
		if text.length() > 2: text += " | "
		text += "STR+" + str(str_bonus)
	if agi_bonus > 0:
		if text.length() > 2: text += " | "
		text += "AGI+" + str(agi_bonus)
	if int_bonus > 0:
		if text.length() > 2: text += " | "
		text += "INT+" + str(int_bonus)
	if def_bonus > 0:
		if text.length() > 2: text += " | "
		text += "DEF+" + str(def_bonus)

	return description + text
