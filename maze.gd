extends TileMap
class_name Maze

@export var ceiling_colour := Color.CADET_BLUE
@export var floor_colour := Color.BURLYWOOD

const num_atlas_cols := 2
const cell_size := 16

class Tile extends Resource:
	var atlas_coords : int
	
	func _init(coords : Vector2i):
		atlas_coords = coords.y * num_atlas_cols + coords.x


func _draw():
	var bounds := get_used_rect()
	
	var top_left := bounds.position * cell_size
	var top_right := Vector2(bounds.end.x, bounds.position.y) * cell_size
	var bottom_left := Vector2(bounds.position.x, bounds.end.y) * cell_size
	var bottom_right := bounds.end * cell_size
	
	draw_colored_polygon([top_left, top_right, bottom_right, bottom_left], floor_colour)


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
