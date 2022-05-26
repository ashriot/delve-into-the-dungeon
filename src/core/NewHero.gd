extends Control

signal add_player

onready var sprite = $Panel/Sprite
onready var job_name = $ClassName
onready var hp = $Stats/HP
onready var crit = $Stats/CRIT
onready var strength = $Stats/Stats/STR/Value
onready var agility = $Stats/Stats/AGI/Value
onready var intellect = $Stats/Stats/INT/Value
onready var defense = $Stats/Stats/DEF/Value
onready var job_perk = $ClassAction
onready var job_desc = $ClassAction/Features
onready var hero_name = $LineEdit

var units := []
var index := 0
var able := false setget, get_able
var game: Game

func init(_game:Game) -> void:
	game = _game
	connect("add_player", game, "_on_add_player")
	setup()

func setup() -> void:
	units.clear()
	print(GameManager.save_data.unlocked_heroes)
	for hero in GameManager.save_data.unlocked_heroes:
		units.append(load("res://resources/jobs/" + hero.to_lower() + ".tres"))
	index = 0
	setup_unit(units[index])
	$LineEdit/CheckBtn.disabled = not self.able

func setup_unit(unit: Player) -> void:
	sprite.frame = unit.frame
	job_name.text = unit.job
	hero_name.text = unit.name
	job_perk.text = unit.job_perk
	job_desc.text = unit.perk_desc
	hp.text = str(unit.hp_max)
	crit.text = str(unit.crit_chance) + "%"
	strength.text = str(unit.strength)
	agility.text = str(unit.agility)
	intellect.text = str(unit.intellect)
	defense.text = str(unit.defense)

func _on_PrevBtn_pressed():
	AudioController.click()
	index = index - 1 if index > 0 else (units.size() - 1)
	setup_unit(units[index])

func _on_NextBtn_pressed():
	AudioController.click()
	index = index + 1 if index < (units.size() - 1) else 0
	setup_unit(units[index])

func _on_BackBtn_pressed():
	AudioController.back()
	hide()

func _on_LineEdit_text_changed(new_text):
	var result = new_text.length() < 2
	$LineEdit/CheckBtn.disabled = result and not self.able

func _on_CheckBtn_pressed():
	AudioController.confirm()
	var new_player = units[index].duplicate() as Player
	new_player.ready_equipment()
	emit_signal("add_player", new_player)
	hide()

func get_able() -> bool:
	return game.players.size() < 4
