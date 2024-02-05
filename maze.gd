extends TileMap
class_name Maze

class Tile extends Resource:
	var texture_index : int
	var warp_angle := 0.0
	var warp_offset := Vector2()
	
	func _init(index : int):
		texture_index = index


func build_tiles_array() -> Array[Tile]:
	var bounds := get_used_rect()
	
	var tiles : Array[Tile] = []
	tiles.resize(bounds.size.x * bounds.size.y)
	
	_fill_tiles(tiles, bounds)
	_set_warps(tiles, bounds.size.x, bounds.position.y * bounds.size.x + bounds.position.x)
	
	return tiles


func _fill_tiles(tiles : Array[Tile], bounds : Rect2i):
	var i := 0
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			tiles[i] = _new_tile(Vector2i(x, y))
			i += 1


func _new_tile(coords : Vector2i) -> Tile:
	return Tile.new(get_cell_source_id(1, coords))


func _set_warps(tiles : Array[Tile], cols : int, index_offset : int):
	for warp in $Warps.get_children():
		var coords : Vector2i = warp.get_coords()
		var index := coords.y * cols + coords.x - index_offset
		
		tiles[index].warp_angle = warp.warp_angle
		tiles[index].warp_offset = warp.warp_offset / Constants.TILEMAP_CELL_SIZE
