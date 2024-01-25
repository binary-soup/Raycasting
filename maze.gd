extends TileMap
class_name Maze

@export var ceiling_colour := Color.CADET_BLUE
@export var floor_colour := Color.BURLYWOOD
@export var diffuse_textures : CompressedTexture2DArray
@export var normal_map : Texture2D
@export var depth_map : Texture2D

const num_altas_rows := 2

class Tile extends Resource:
	var texture_index : int
	
	func _init(coords : Vector2i):
		texture_index = coords.y * num_altas_rows + coords.x


func _draw():
	var bounds := get_used_rect()
	
	var top_left := bounds.position * rendering_quadrant_size
	var top_right := Vector2(bounds.end.x, bounds.position.y) * rendering_quadrant_size
	var bottom_left := Vector2(bounds.position.x, bounds.end.y) * rendering_quadrant_size
	var bottom_right := bounds.end * rendering_quadrant_size
	
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
