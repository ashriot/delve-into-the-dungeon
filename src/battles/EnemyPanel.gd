extends Control
class_name EnemyPanel

signal done

onready var button: = $Button
onready var sprite: = $Sprite
onready var hp_percent: = $TextureProgress
onready var target: = $Target
onready var anim: = $AnimationPlayer

var enemy: Enemy
var valid_target: bool

var hp_cur: int setget set_hp_cur

func init(battle, _enemy: Enemy) -> void:
	enemy = _enemy
	hp_percent.max_value = enemy.hp_max
	self.hp_cur = enemy.hp_max
	targetable(false)
	button.connect("pressed", battle, "_on_EnemyPanel_pressed", [self])
	add_to_group("enemy_panels")

func get_def(stat) -> int:
	if stat == Enum.StatType.AGI: return enemy.agility
	elif stat == Enum.StatType.DEF: return enemy.defense
	elif stat == Enum.StatType.INT: return enemy.intellect
	elif stat == Enum.StatType.STR: return enemy.strength
	return -999

func take_hit() -> void:
	anim.play("Hit")

func attack() -> void:
	anim.play("Attack")
	yield(anim, "animation_finished")
	emit_signal("done")

func set_hp_cur(value: int):
	hp_cur = value
	hp_percent.value = value

func targetable(value: bool):
	valid_target = value
	if valid_target: target.show()
	else: target.hide()
