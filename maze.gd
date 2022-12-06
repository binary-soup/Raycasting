extends TileMap
class_name Maze

const num_atlas_cols := 2
const cell_size := 16

class Tile extends Resource:
	var atlas_coords : int
	
	func _init(coords : Vector2i):
		atlas_coords = coords.y * num_atlas_cols + coords.x


func get_tiles() -> Array[Tile]:
	var tiles : Array[Tile] = []
	var bounds := get_used_rect()
	
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			tiles.append(_new_tile(Vector2i(x, y)))
	
	return tiles


func _new_tile(pos : Vector2i) -> Tile:
	var coords := get_cell_atlas_coords(0, pos)
	return Tile.new(coords)
