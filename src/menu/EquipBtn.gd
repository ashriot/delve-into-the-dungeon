extends PressButton
class_name EquipBtn

onready var color = $Bg.modulate
onready var title = $Bg/Title
onready var sprite = $Bg/Sprite

var empty: bool
var equip: Equipment

func init(menu):
	var err = connect("long_pressed", menu, "_on_EquipButton_long_pressed", [self])
	err = connect("pressed", menu, "_on_EquipButton_pressed", [self])
	if err: print("There was an error connecting: ", err)

func setup(equipment: Equipment, slot: int) -> void:
	sprite.frame = slot + 30
	if equipment == null:
		empty = true
		title.text = ""
		modulate = Enums.gray_color
		return
	equip = equipment
	empty = false
	title.text = equipment.get_name()
	modulate = colorize(equipment.quality)

func colorize(quality: int) -> Color:
	if quality == 0: return Enums.worn
	if quality == 1: return Enums.common
	if quality == 2: return Enums.fine
	if quality == 3: return Enums.exquisite
	if quality == 4: return Enums.masterwork
	if quality == 5: return Enums.artefact
	return Color.black
