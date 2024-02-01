extends TileMap
class_name Maze

class Tile extends Resource:
	var texture_index : int
	var speed_scale : float
	
	func _init(index : int, data : CustomTileData):
		texture_index = index
		speed_scale = data.speed_scale


class CustomTileData extends Resource:
	var speed_scale := 1.0
	
	func _init(data : TileData):
		if data == null:
			return
		
		speed_scale = data.get_custom_data("speed_scale")


func get_tiles() -> Array[Tile]:
	var tiles : Array[Tile] = []
	var bounds := get_used_rect()
	
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			tiles.append(_new_tile(Vector2i(x, y)))
	
	return tiles


func _new_tile(coords : Vector2i) -> Tile:
	return Tile.new(get_cell_source_id(1, coords), CustomTileData.new(get_cell_tile_data(2, coords)))
