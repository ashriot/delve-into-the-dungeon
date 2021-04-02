extends Control
class_name EnemyPanel

signal done
signal show_dmg(text)

var DamageText = preload("res://src/battles/DamageText.tscn")

onready var button: = $Button
onready var sprite: = $Sprite
onready var hp_percent: = $TextureProgress
onready var target: = $Target
onready var anim: = $AnimationPlayer
onready var hit: = $Hit

var enemy: Enemy
var hp_cur: int setget set_hp_cur
var hp_max: int
var valid_target: bool
var enabled: bool

var hexes: Array

func init(battle, _enemy: Enemy) -> void:
	hexes = []
	enabled = true
	enemy = _enemy
	sprite.frame = enemy.frame
	hp_max = enemy.hp_max
	hp_percent.max_value = hp_max
	self.hp_cur = hp_max
	targetable(false)
	button.connect("pressed", battle, "_on_EnemyPanel_pressed", [self])
	connect("show_dmg", battle, "show_dmg_text")
	add_to_group("enemy_panels")

func get_def(stat) -> int:
	if stat == Enum.StatType.AGI: return enemy.agility
	elif stat == Enum.StatType.DEF: return enemy.defense
	elif stat == Enum.StatType.INT: return enemy.intellect
	elif stat == Enum.StatType.STR: return enemy.strength
	return -999

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
	var def = get_def(item.stat_vs)
	var rel_def = (def - hit.atk) / hit.atk + 0.5
	var def_mod = pow(0.95, 27 * rel_def)
	var pos = rect_global_position
	pos.x -= 6
	pos.y += rect_size.y / 2
	var damage_text = DamageText.instance()
	damage_text.rect_global_position = pos
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
			gain_hex(hex)
			emit_signal("show_dmg", hex, pos)
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")


func attack() -> void:
	anim.play("Attack")
	yield(anim, "animation_finished")
	emit_signal("done")

func gain_hex(hex_name: String) -> void:
	hexes.append(hex_name)
	if hex_name == "Slow": enemy.agility -= 10

func targetable(value: bool, display = true):
	if not enabled: return
	if not alive(): value = false
	valid_target = value
	if valid_target:
		if display: target.show()
		hit.show()
	else:
		target.hide()
		hit.hide()

func update_hit_chance(hit_chance: int, stat) -> void:
	if not (enabled or alive() or valid_target): return
	var value = 100
	if stat != Enum.StatType.NA:
		value = get_hit_and_crit_chance(hit_chance, 0, stat)[0]
	hit.text = str(value) + "%"

func get_hit_and_crit_chance(hit_chance: int, crit_chance: int, stat) -> Array:
	var hit = 100
	var crit = 0
	if stat != Enum.StatType.NA:
		hit = clamp(hit_chance - (get_def(stat) * 5), 0, 100)
		crit = crit_chance
	return [hit, crit]

func alive() -> bool:
	return hp_cur > 0

func set_hp_cur(value: int):
	hp_cur = clamp(value, 0, hp_max)
	hp_percent.value = value
