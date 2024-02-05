extends Area2D
class_name WarpField

@export_node_path("WarpField") var target_path
@onready var target : WarpField = get_node(target_path)

var tile_dir : Vector2
var warp_offset : Vector2
var warp_angle : float


func get_coords() -> Vector2i:
	return Vector2i((position / Constants.TILEMAP_CELL_SIZE).floor())


func _ready():
	tile_dir = Vector2(0.0, -1.0).rotated(rotation)
	warp_offset = target.position - position
	warp_angle = rotation - target.rotation


func _on_area_entered(area : Area2D):
	var player : Player = area.get_parent()
	
	player.position += tile_dir * (Constants.TILEMAP_CELL_SIZE + 0.2)
	player.position = (player.position - position).rotated(warp_angle) + position + warp_offset
	
	player.warp_rotation(warp_angle)
