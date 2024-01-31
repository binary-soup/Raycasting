extends TileMap
class_name Maze

class Tile extends Resource:
	var texture_index : int
	
	func _init(index : int):
		texture_index = index


func get_tiles() -> Array[Tile]:
	var tiles : Array[Tile] = []
	var bounds := get_used_rect()
	
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			tiles.append(_new_tile(Vector2i(x, y)))
	
	return tiles


func _new_tile(coords : Vector2i) -> Tile:
	return Tile.new(get_cell_source_id(1, coords))
