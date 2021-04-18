extends BattlePanel
class_name PlayerPanel

onready var hp_cur_display = $HPCur
onready var selector = $Selector
onready var outline = $Outline

var tab: int setget set_tab

var ready:= true setget set_ready
var selected:= false setget set_selected

var enc_lv: float
var gained_xp: bool

func init(battle):
	.init(battle)
	anim.playback_speed = 1 / GameManager.spd
	pos = rect_global_position
	pos.x -= 16
	pos.y += rect_size.y / 2
# warning-ignore:return_value_discarded
	button.connect("pressed", battle, "_on_PlayerPanel_pressed", [self])
# warning-ignore:return_value_discarded
	connect("died", battle, "_on_PlayerPanel_died", [self])

func setup(_unit):
	unit = _unit
	unit.reset_xp()
	tab = unit.tab
	.setup(_unit)
	self.hp_cur = unit.hp_cur
	sprite.position.y = 2
	self.selected = false
	self.ready = true

func update_status() -> void:
	if statuses.size() == 0: status.frame = 90
	.update_status()

func set_selected(value: bool):
	if !ready: return
	selected = value
	if selected: selector.show()
	else: selector.hide()

func set_ready(value: bool):
	ready = value
	if ready:
		if sprite.frame > 10:
			sprite.frame -= 10
		outline.modulate.a = 1
		if blocking > 0: self.blocking = 0
		decrement_boons("Start")
	else:
		if sprite.frame < 10:
			sprite.frame += 10
		outline.modulate.a = 0.15

func set_hp_cur(value):
	if hp_cur > value and !gained_xp:
		calc_hp_xp()
	.set_hp_cur(value)
	unit.hp_cur = clamp(value, 0, hp_max)
	if blocking > 0:
		hp_cur_display.modulate = Color.slategray
		hp_cur_display.text = str(blocking)
	else:
		hp_cur_display.modulate = Color.white
		hp_cur_display.text = str(hp_cur)

func die() -> void:
	.die()

func victory() -> void:
	if !ready: self.ready = true
	print(unit.name, " ", unit.gains)
	anim.play("Victory")

func set_tab(value) -> void:
	tab = value
	unit.tab = value

func get_melee_penalty() -> bool:
	return get_index() > 1 and !unit.has_perk("Reach")

func take_hit(hit) -> void:
	.take_hit(hit)
	if gained_xp: return
	calc_xp(hit.item.stat_vs, 0.5)
	calc_xp(hit.stat_hit, 0.25)
	gained_xp = true

func take_friendly_hit(user, item) -> void:
	var prev_hp = hp_cur
	.take_friendly_hit(user, item)
	if prev_hp < hp_cur: calc_xp(item.stat_vs, 0.5)

func calc_xp(stat, mod = 1.0) -> void:
	if stat < 2: return
	var id = stat - 1
	if id == 5:
		print("NA")
		return
	var stat_val = unit.get_stat(stat)
	var threshold = float((enc_lv * 1) +  (15 * 1))
	var xp = 1 - pow(0.85, threshold / (stat_val + unit.gains[0]))
	var prev = unit.xp[id]
	unit.xp[id] += xp * unit.xp_cut[id] * mod
	unit.xp_cut[id] *= 1 - 0.66 * mod
	if unit.xp[id] > 1:
		unit.xp[id] -= 1
		unit.gains[id] += 1
	print(unit.name, " ", Enum.get_stat_name(stat), ": ", prev, " -> ", unit.xp[id], " cut: ", unit.xp_cut[id])

func calc_hp_xp() -> void:
	var stat_val = unit.get_stat(Enum.StatType.MaxHP)
	var threshold = float((enc_lv * 10) +  (15 * 10))
	var xp = 1 - pow(0.85, threshold / (stat_val + unit.gains[0]))
	var prev = unit.xp[0]
	unit.xp[0] += xp * unit.xp_cut[0]
	unit.xp_cut[0] *= 0.66
	if unit.xp[0] > 1:
		unit.xp[0] -= 1
		unit.gains[0] += randi() % 3 + 3
	print(unit.name, " Max HP: ", prev, " -> ", unit.xp[0], " cut: ", unit.xp_cut[0])

func calc_job_xp() -> int:
	var ranks_up = 0
	var stat_val = unit.job_lv + 1
	var threshold = float(enc_lv)
	var xp = 1 - pow(0.9, threshold / stat_val)
	var prev = unit.job_xp * rand_range(0.85, 1.15)
	unit.job_xp += xp
	if unit.job_xp > 1:
		unit.job_xp -= 1
		unit.job_lv += 1
		ranks_up += 1
	print(unit.name, " Job XP ", prev, " -> ", unit.job_xp)
	return ranks_up
