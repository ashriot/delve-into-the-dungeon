extends Node2D
class_name Chest

const TILE_SIZE = 8

onready var sprite = $Sprite

var tile
var opened: = false

func init(game, x, y) -> Node2D:
	tile = Vector2(x, y)
	$Sprite.frame = 0
	position =  tile * TILE_SIZE
	game.add_child(self)
	return self

func open() -> void:
	# Get random Loot
	opened = true
	sprite.frame = 1

func remove() -> void:
	queue_free()
