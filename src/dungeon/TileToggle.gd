extends TileMap
class_name TileToggle

var tex_array = [
	load("res://assets/images/sheets/tile_sea.png"),
	load("res://assets/images/sheets/tile_fae.png"),
	load("res://assets/images/sheets/tile_lab.png"),
	load("res://assets/images/sheets/tile_crypt.png"),
	load("res://assets/images/sheets/tile_palace.png"),
	load("res://assets/images/sheets/tile_ruins.png")]

export(int) var index setget update_tileset
export(Resource) var tileset

func update_tileset(new_index):
	var extent = 0 if tex_array.empty() else tex_array.size() - 1
	index = int(clamp(new_index, 0, extent))
	if tileset is ImageTexture and tex_array[index] != null:
		tileset.image = tex_array[index]
