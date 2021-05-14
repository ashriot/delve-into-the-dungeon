extends Control

onready var sprite = $Panel/Sprite
onready var job_name = $ClassName
onready var hp = $Stats/HP
onready var strength = $Stats/Stats/STR/Value
onready var agility = $Stats/Stats/AGI/Value
onready var intellect = $Stats/Stats/INT/Value
onready var defense = $Stats/Stats/DEF/Value
onready var job_perk = $ClassAction
onready var job_desc = $ClassAction/Features
onready var hero_name = $HeroName

var units: = []
var index: = 0

func init(game:Game) -> void:
	setup()

func setup() -> void:
	units.clear()
	for hero in GameManager.save_data.unlocked_heroes:
		if hero == "Fighter": units.append(load("res://resources/jobs/fighter.tres"))
		elif hero == "Thief": units.append(load("res://resources/jobs/thief.tres"))
		elif hero == "Sorcerer": units.append(load("res://resources/jobs/sorcerer.tres"))
		elif hero == "Wizard": units.append(load("res://resources/jobs/wizard.tres"))
	index = 0
	setup_unit(units[index])

func setup_unit(unit: Player) -> void:
	sprite.frame = unit.frame
	job_name.text = unit.job
	hero_name.text = unit.name
	job_perk.text = unit.job_perk
	job_desc.text = unit.perk_desc
	hp.text = str(unit.hp_max)
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
