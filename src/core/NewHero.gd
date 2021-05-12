extends Control

onready var job_name = $ClassName
onready var hp = $Stats/HP
onready var strength = $Stats/Stats/STR/Value
onready var agility = $Stats/Stats/AGI/Value
onready var intellect = $Stats/Stats/INT/Value
onready var defense = $Stats/Stats/DEF/Value
onready var class_action = $ClassAction

var units = []

func init(game:Game) -> void:
	pass

func setup() -> void:
	for hero in GameManager.save_data.unlocked_heroes:
		if hero == "Fighter": units.append(load("res://resources/jobs/fighter.tres"))
		elif hero == "Thief": units.append(load("res://resources/jobs/thief.tres"))
		elif hero == "Sorcerer": units.append(load("res://resources/jobs/sorcerer.tres"))
		elif hero == "Wizard": units.append(load("res://resources/jobs/wizard.tres"))
	setup_unit(units[0])

func setup_unit(unit: Player) -> void:
	job_name.text = unit.job
	class_action.text = unit.job_tab
	hp.text = str(unit.hp_max)

func _on_PrevBtn_pressed():
	pass # Replace with function body.


func _on_NextBtn_pressed():
	pass # Replace with function body.
