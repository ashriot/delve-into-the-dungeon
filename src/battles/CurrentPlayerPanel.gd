extends Control
class_name CurrentPlayerPanel

onready var portrait = $Portrait as Sprite
onready var name_label = $Name as RichTextLabel
onready var ap = $ApGauge as TextureRect
onready var quick = $QuickIcon as TextureRect
onready var sorcery = $Resources/Sorcery as Control
onready var perform = $Resources/Perform as Control
onready var sp_cur_gauge = $Resources/Sorcery/SpCur as TextureRect
onready var sp_max_gauge = $Resources/Sorcery/SpMax as TextureRect
onready var bp_cur_gauge = $Resources/Perform/BpCur as TextureRect
onready var bp_max_gauge = $Resources/Perform/BpMax as TextureRect


func setup(cur_player: PlayerPanel) -> void:
	portrait.frame = cur_player.unit.frame + 20
	name_label.text = cur_player.unit.name
	ap.rect_size.x = cur_player.unit.ap * 12
	var quick_color = "#fff" if cur_player.quick_actions > 0 else "#333"
	quick.modulate = quick_color
	var unit = cur_player.unit
	if unit.job == "Sorcerer":
		var sp_cur = unit.job_data["sp_cur"]
		var sp_max = unit.job_data["sp_max"]
		sp_cur_gauge.rect_size.x = sp_cur * 3
		sp_cur_gauge.rect_position.x = 17 - sp_max * 3
		sp_max_gauge.rect_size.x = sp_max * 3
		sp_max_gauge.rect_position.x = 17 - sp_max * 3
		sorcery.show()
	else:
		sorcery.hide()
	if unit.job == "Bard":
		var bp_cur = unit.job_data["bp_cur"]
		var bp_max = unit.job_data["bp_max"]
		bp_cur_gauge.rect_size.x = (bp_cur * 3 - (1 if bp_cur > 1 else 0))
		bp_cur_gauge.rect_position.x = 21 - (bp_max * 3 - (1 if bp_max > 1 else 0))
		bp_max_gauge.rect_size.x = (bp_max * 3 - (1 if bp_max > 1 else 0))
		bp_max_gauge.rect_position.x = 21 - (bp_max * 3 - (1 if bp_max > 1 else 0))
		perform.show()
	else:
		perform.hide()
	show()
