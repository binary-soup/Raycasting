extends Node2D

@export var raycast_mode := true

@onready var tile_map := $TileMap
@onready var player := $Player
@onready var camera := $Player/Camera2D

const fov := PI/4
const cell_size := 16

const floor_colour := Color.BURLYWOOD
const ceiling_colour := Color.CADET_BLUE

const colours := {
	Vector2i(0, 0): Color.RED,
	Vector2i(1, 0): Color.YELLOW,
	Vector2i(0, 1): Color.GREEN,
	Vector2i(1, 1): Color.DODGER_BLUE,
}

var viewport_size : Vector2i


func _ready():
	if raycast_mode:
		tile_map.visible = false
		player.visible = false
	else:
		camera.current = true


func _process(delta):
	if raycast_mode:
		queue_redraw()


func _draw():
	if not raycast_mode:
		return
	
	viewport_size = get_viewport_rect().size
	for x in viewport_size.x:
		_render_column(x, lerp_angle(-fov, fov, float(x) / viewport_size.x))


func _render_column(x : float, angle : float):
	var dir := Vector2.UP.rotated(angle + player.rotation)
	
	var start_pos : Vector2 = player.position
	var pos := start_pos
	
	var mid_point = viewport_size.y / 2
	var wall_height := 0.0
	
	while true:
		pos = _calc_intersection_point(pos, dir) + dir
		
		var dist := pos.distance_to(start_pos) * cos(angle) # fish eye fix
		if dist > 1000:
			break
		
		var coords : Vector2i = tile_map.get_cell_atlas_coords(0, tile_map.local_to_map(pos))
		if coords == Vector2i(-1, -1):
			continue
			
		wall_height = (viewport_size.y / 2) / dist * cell_size		
		draw_line(Vector2(x, mid_point - wall_height), Vector2(x, mid_point + wall_height), colours[coords])
		break
	
	draw_line(Vector2(x, 0), Vector2(x, mid_point - wall_height), ceiling_colour)
	draw_line(Vector2(x, mid_point + wall_height), Vector2(x, viewport_size.y), floor_colour)
	


func _calc_intersection_point(pos : Vector2, dir : Vector2) -> Vector2:
	var cell := Rect2i(tile_map.local_to_map(pos) * cell_size, Vector2i(cell_size, cell_size))
	
	if dir == Vector2.UP:
		return Vector2(pos.x, cell.position.y)
		
	if dir == Vector2.DOWN:
		return Vector2(pos.x, cell.end.y)
		
	if dir == Vector2.LEFT:
		return Vector2(cell.position.x, pos.y)
		
	if dir == Vector2.RIGHT:
		return Vector2(cell.end.x, pos.y)
	
	var point : Vector2
	var slope := dir.y / dir.x
	
	if dir.y < 0:
		point = _intersect_horizontal_line(cell.position.y, slope, pos)
	else:
		point = _intersect_horizontal_line(cell.end.y, slope, pos)
		
	if point.x < cell.position.x:
		return _intersect_vertical_line(cell.position.x, slope, pos)
	
	if point.x > cell.end.x:
		return _intersect_vertical_line(cell.end.x, slope, pos)

	return point
	

func _intersect_horizontal_line(y : float, slope : float, pos : Vector2) -> Vector2:
	var initial := -slope * pos.x + pos.y
	return Vector2((y - initial) / slope, y)
	

func _intersect_vertical_line(x : float, slope : float, pos : Vector2) -> Vector2:
	var initial := 1 / -slope * pos.y + pos.x
	return Vector2(x, (x - initial) * slope)
