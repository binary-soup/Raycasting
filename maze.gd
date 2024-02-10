extends TileMap
class_name Maze

var warp_fields := {}

class Tile extends Resource:
	var texture_index : int
	var warp_index := -1
	var num_warps := 0
	
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
	
	for coords in warp_fields.keys():
		for warp in warp_fields[coords]:
			warps.append(warp)
	
	return warps


func get_warp(pos : Vector2, dir : Vector2) -> Warp:
	var coords := Vector2i(pos.floor())
	if not coords in warp_fields:
		return null
		
	var warps : Array = warp_fields[coords]
	var warp : Warp = warps[0]
	var edge := _calc_enter_egde(coords, pos, dir)
	
	for i in range(1, warps.size()):
		if edge.dot(warps[i].dir) < -0.01:
			return warps[i]
	
	return warp


func _ready():
	for warp in $Warps.get_children():
		var coords : Vector2i = warp.get_coords()
		
		if coords in warp_fields:
			warp_fields[coords].append(warp)
		else:
			warp_fields[coords] = [warp]


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
	
	for coords in warp_fields.keys():
		var index : int = coords.y * cols + coords.x - index_offset
		var count : int = warp_fields[coords].size()
		
		tiles[index].warp_index = i
		tiles[index].num_warps = count
		i += count


func _calc_enter_egde(cell : Vector2, pos : Vector2, dir : Vector2) -> Vector2:
	if dir.y == -1.0:
		return Vector2.UP
	if dir.y == 1.0:
		return Vector2.DOWN
	if dir.x == -1.0:
		return Vector2.LEFT
	if dir.x == 1.0:
		return Vector2.RIGHT
	
	var slope := dir.y / dir.x
	
	var point : float
	var normal : Vector2
	
	if dir.y < 0.0:
		point = _intersect_edge(cell.y, slope, pos)
		normal = Vector2.UP
	else:
		point = _intersect_edge(cell.y + 1.0, slope, pos)
		normal = Vector2.DOWN
	
	if point < cell.x:
		return Vector2.LEFT
	elif point > cell.x + 1.0:
		return Vector2.RIGHT
	
	return normal


func _intersect_edge(y : float, slope : float, pos : Vector2) -> float:
	var initial := -slope * pos.x + pos.y;
	return (y - initial) / slope
