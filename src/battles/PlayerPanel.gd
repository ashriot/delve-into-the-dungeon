extends Control
class_name PlayerPanel

signal show_dmg(text)

onready var HPCur = $HPCur
onready var HPPercent = $HPPercent
onready var portrait = $Potrait
onready var selector = $Selector
onready var outline = $Outline
onready var target = $Target
onready var button = $Button
onready var anim = $AnimationPlayer

onready var status = $Status

var player: Player
var hp_max: int
var hp_cur: int setget set_hp_cur
var ready:= true setget set_ready
var selected:= false setget set_selected
var targetable: bool
var enabled: bool
var valid_target: bool
var hexes: Array

var blocking: int setget set_blocking

func init(battle, _player: Player):
	enabled = true
	self.ready = true
	hexes = []
	show()
	player = _player
	portrait.frame = player.frame
	self.hp_max = player.hp_max
	self.hp_cur = player.hp_cur
	HPPercent.max_value = hp_max
	HPPercent.value = hp_cur
	button.connect("pressed", battle, "_on_PlayerPanel_pressed", [self])
	connect("show_dmg", battle, "show_dmg_text")

func get_stat(stat) -> int:
	return player.get_stat(stat)

func alive() -> bool:
	return hp_cur > 0

func take_hit(hit: Hit, hit_stat: int) -> void:
	var item = hit.item as Item
	var hit_and_crit = get_hit_and_crit_chance(hit.hit_chance, hit.crit_chance, hit_stat)
	var hit_chance = hit_and_crit[0]
	var crit_chance = hit_and_crit[1]
	var miss = false
	var hit_roll = randi() % 100 + 1
	print("Hit Chance: ", hit_chance, "% -> Roll: ", (100 - hit_roll))
	if hit_roll > hit_chance:
		miss = true
	var dmg = int((item.multiplier * hit.atk) + hit.bonus_dmg) * (1 + hit.dmg_mod)
	var def = get_stat(item.stat_vs)
	var rel_def = (def - hit.atk) / hit.atk + 0.5
	var def_mod = pow(0.95, 27 * rel_def)
	var pos = rect_global_position
	pos.x -= 6
	pos.y += rect_size.y / 2
	var dmg_text = ""
	if not miss:
		self.hp_cur -= dmg
		dmg_text = str(dmg)
		anim.play("Hit")
	else:
		dmg_text = "MISS"
	emit_signal("show_dmg", dmg_text, pos)
	if item.inflict_hexes.size() > 0 and not miss:
		for hex in item.inflict_hexes:
			yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
			var success = gain_hex(hex)
			if success: emit_signal("show_dmg", hex, pos)
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")

func take_friendly_hit(user: PlayerPanel, item: Item) -> void:
	var dmg = int(item.multiplier * get_stat(item.stat_used))
	var def = get_stat(item.stat_vs)
	var pos = rect_global_position
	pos.x += 3
	pos.y += rect_size.y / 2
	var dmg_text = ""
	print(item)
	if item.damage_type == Enum.DamageType.HEAL:
		self.hp_cur += dmg
		dmg_text = str(dmg)
#		anim.play("Hit")
	elif "Shield" in item.name:
		dmg_text = "Block:" + str(dmg)
		self.blocking += dmg
	emit_signal("show_dmg", dmg_text, pos)
	if item.inflict_hexes.size() > 0:
		for hex in item.inflict_hexes:
			yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
			var success = gain_hex(hex)
			if success: emit_signal("show_dmg", hex, pos)
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")

func set_blocking(value: int) -> void:
	print("Blocking: ", value, " martial damage.")
	blocking = value
	status.frame = 79

func gain_hex(hex_name: String) -> bool:
	if hexes.has(hex_name): return false
	hexes.append(hex_name)
	if hex_name == "Slow": player.agi_bonus -= 10
	return true

func get_hit_and_crit_chance(hit_chance: int, crit_chance: int, stat) -> Array:
	var hit = 100
	var crit = 0
	if stat != Enum.StatType.NA:
		hit = clamp(hit_chance - (get_stat(stat) * 5), 0, 100)
		crit = crit_chance
	return [hit, crit]

func set_selected(value: bool):
	if !ready: return
	selected = value
	if selected: selector.show()
	else: selector.hide()

func set_ready(value: bool):
	ready = value
	if ready: outline.modulate.a = 1
	else: outline.modulate.a = 0.15

func set_hp_cur(value):
	hp_cur = value
	player.hp_cur = value
	HPCur.text = pad_int(hp_cur, 3)
	HPPercent.value = hp_cur

func targetable(value: bool, display = true):
	if not enabled: return
	if not alive(): value = false
	valid_target = value
	if valid_target:
		if display: target.show()
	else:
		target.hide()

func pad_int(num: int, digits: int) -> String:
	var text = str(num)
	return text
