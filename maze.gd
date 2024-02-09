extends TileMap
class_name Maze

var warp_fields := {}

class Tile extends Resource:
	var texture_index : int
	var warp_index := -1
	
	func _init(index : int):
		texture_index = index


func build_tiles_array() -> Array[Tile]:
	var bounds := get_used_rect()
	
	var tiles : Array[Tile] = []
	tiles.resize(bounds.size.x * bounds.size.y)
	
	_fill_tiles(tiles, bounds)
	_set_warps(tiles, bounds.size.x, bounds.position.y * bounds.size.x + bounds.position.x)
	
	return tiles


func build_warps_array() -> Array[Warp]:
	var warps : Array[Warp] = []
	
	for key in warp_fields.keys():
		warps.append(warp_fields[key])
	
	return warps


func get_warp(pos : Vector2) -> Warp:
	var coords := Vector2i((pos / Constants.TILEMAP_CELL_SIZE).floor())
	
	if coords in warp_fields:
		return warp_fields[coords]
		
	return null


func _ready():
	for warp in $Warps.get_children():
		var coords : Vector2i = warp.get_coords()
		warp_fields[coords] = warp


func _fill_tiles(tiles : Array[Tile], bounds : Rect2i):
	var i := 0
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			tiles[i] = _new_tile(Vector2i(x, y))
			i += 1


func _new_tile(coords : Vector2i) -> Tile:
	return Tile.new(get_cell_source_id(1, coords))


func _set_warps(tiles : Array[Tile], cols : int, index_offset : int):
	var i := 0
	
	for key in warp_fields.keys():
		var index : int = key.y * cols + key.x - index_offset
		
		tiles[index].warp_index = i
		i += 1
