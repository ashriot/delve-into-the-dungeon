extends Node2D
class_name Chest

signal opened_chest()

const TILE_SIZE = 8

var tile
var opened: = false

func init(dungeon, x, y) -> Node2D:
	var _err = connect("opened_chest", dungeon.game, "_on_Chest_opened")
	tile = Vector2(x, y)
	$Sprite.frame = dungeon.dungeon_id
	position =  tile * TILE_SIZE
	dungeon.add_child(self)
	return self

func open() -> void:
	opened = true
	emit_signal("opened_chest")

func remove() -> void:
	queue_free()
