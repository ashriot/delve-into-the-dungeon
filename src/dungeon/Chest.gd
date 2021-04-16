extends Node2D
class_name Chest

signal opened_chest()

const TILE_SIZE = 8

onready var sprite = $Sprite

var tile
var opened: = false

func init(dungeon, x, y) -> Node2D:
	connect("opened_chest", dungeon.game, "_on_Chest_opened")
	tile = Vector2(x, y)
	$Sprite.frame = 0
	position =  tile * TILE_SIZE
	dungeon.add_child(self)
	return self

func open() -> void:
	opened = true
	sprite.frame = 1
	emit_signal("opened_chest")

func remove() -> void:
	queue_free()
