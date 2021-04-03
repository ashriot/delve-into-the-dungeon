extends Control
class_name PlayerPanel

signal show_dmg(text)
signal show_text(text)
signal done

onready var HPCur = $HPCur
onready var hp_percent = $TextureProgress
onready var sprite = $Sprite
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
var enabled: bool
var valid_target: bool

var hexes: Array
var boons: Array
var statuses: = []
var delay: = 0
var status_ptr: int
var blocking: int setget set_blocking

func init(battle, _player: Player):
	enabled = true
	self.ready = true
	hexes = []
	show()
	player = _player
	sprite.frame = player.frame
	self.hp_max = player.hp_max
	self.hp_cur = player.hp_cur
	hp_percent.max_value = hp_max
	hp_percent.value = hp_cur
	button.connect("pressed", battle, "_on_PlayerPanel_pressed", [self])
# warning-ignore:return_value_discarded
	connect("show_dmg", battle, "show_dmg_text")
	connect("show_text", battle, "show_text")

func _physics_process(delta: float) -> void:
	if statuses.size() == 0: return
	if delay == 0:
		status_ptr = (status_ptr + 1) % statuses.size()
		status.frame = statuses[status_ptr][1]
		delay = 60 * GameManager.spd
	else: delay -= 1

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
	dmg = int(dmg * def)
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
			var success = gain_hex(hex[0], hex[1])
			if success: emit_signal("show_text", hex[0].name, pos)
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")

func take_friendly_hit(user: PlayerPanel, item: Item) -> void:
	var dmg = int(item.multiplier * user.get_stat(item.stat_used))
	var def = int(get_stat(item.stat_vs) * item.multiplier)
	var pos = rect_global_position
	pos.x += 3
	pos.y += rect_size.y / 2
	var dmg_text = ""
	if item.damage_type == Enum.DamageType.HEAL:
		self.hp_cur += dmg + def
		dmg_text = str(dmg)
#		anim.play("Hit")
	elif item.sub_type == Enum.SubItemType.SHIELD:
		dmg_text = "Block:" + str(dmg)
		self.blocking += dmg
	if dmg > 0: emit_signal("show_text", dmg_text, pos)
	if item.inflict_hexes.size() > 0:
		for hex in item.inflict_hexes:
			yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
			var success = gain_hex(hex[0], hex[1])
			if success: emit_signal("show_text", hex[0].name, pos)
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	if item.inflict_boons.size() > 0:
		for boon in item.inflict_boons:
			var success = gain_boon(boon[0], boon[1])
			if success: emit_signal("show_text", boon[0].name, pos)
			yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")

func set_blocking(value: int) -> void:
	print("Blocking: ", value, " martial damage.")
	blocking = value
	if blocking > 0: add_status(["Block", 79])
	else: remove_status("Block")

func gain_hex(hex: Effect, duration: int) -> bool:
	if hexes.has(hex.name): return false
	hexes.append(hex.name)
	statuses.append([hex.name, hex.frame])
	if hex.name == "Slow": player.agi_bonus -= 5
	return true

func gain_boon(boon: Effect, duration: int) -> bool:
	var found = false
	for b in boons: if b[0].name == boon.name:
		found = true
		b[1] = duration
	if not found:
		boons.append([boon, duration])
		statuses.append([boon.name, boon.frame])
		if boon.name == "Fast": player.agi_bonus += 5
	return true

func remove_boon(find: Effect) -> void:
	print("Removing: ", find.name)
	for boon in boons:
		if boon[0] == find:
			boons.remove(boons.find(boon))
			break
	for s in statuses:
		if s[0] == find.name:
			remove_status(find.name)
			break
	if find.name == "Fast": player.agi_bonus += 5

func decrement_boons(timing: String) -> void:
	for boon in boons:
		if (boon[0].turn_end and timing == "End") or \
			(boon[0].turn_start and timing == "Start"):
				print(boon[0].name, " -> ", boon[1])
				boon[1] -= 1
				if boon[1] == 0:
					remove_boon(boon[0])


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
	if ready:
		outline.modulate.a = 1
		if blocking > 0: self.blocking = 0
		decrement_boons("Start")
	else: outline.modulate.a = 0.15

func set_hp_cur(value):
	hp_cur = value
	player.hp_cur = value
	HPCur.text = str(hp_cur)
	hp_percent.value = hp_cur

func has_perk(perk_name: String) -> bool:
	return player.has_perk(perk_name)

func targetable(value: bool, display = true):
	if not enabled: return
	if not alive(): value = false
	valid_target = value
	if valid_target:
		if display: target.show()
	else:
		target.hide()

func add_status(value: Array) -> void:
	statuses.append(value)
	update_status()

func remove_status(value: String) -> void:
	for s in statuses:
		if s[0] == value:
			statuses.remove(statuses.find(s))
			break
	update_status()

func update_status() -> void:
	if statuses.size() == 0:
		status.frame = 90
	status_ptr = 0
	delay = 0
