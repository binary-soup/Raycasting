extends TileMap
class_name Maze

@onready var lights_node := $Lights

@export var ceiling_colour := Color.CADET_BLUE
@export var floor_colour := Color.BURLYWOOD
@export var tilemap_atlas : Texture2D
@export var tilemap_normal_map : Texture2D
@export var ambient_colour : Color
@export var light_att : Vector3

const atlas_dim := Vector2i(2, 2)
const cell_size := 16

class Tile extends Resource:
	var atlas_coords : Vector2i
	
	func _init(coords : Vector2i):
		atlas_coords = coords


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


func get_light_count() -> int:
	return lights_node.get_child_count()


func get_lights() -> Array:
	return lights_node.get_children()


func _new_tile(pos : Vector2i) -> Tile:
	var coords := get_cell_atlas_coords(0, pos)
	return Tile.new(coords)
