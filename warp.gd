extends Node2D
class_name Warp

@export_node_path("Warp") var target_path
@onready var target : Warp = get_node(target_path)

var dir : Vector2
var offset : Vector2
var angle : float


func get_warps() -> Array:
	return [self]


func get_coords() -> Vector2i:
	return Vector2i((position / Constants.TILEMAP_CELL_SIZE).floor())


func calc_normal(pos : Vector2) -> Vector2:
	var diff := pos - position
	
	if abs(diff.x) >= abs(diff.y):
		diff.y = 0.0
	else:
		diff.x = 0.0
	
	return diff.normalized()


func recalculate():
	dir = Vector2.UP.rotated(rotation)
	var target_dir := Vector2.UP.rotated(target.rotation)
	
	offset = (target.position - position) / Constants.TILEMAP_CELL_SIZE
	angle = (rotation - target.rotation + PI * dir.dot(target_dir))


func _ready():
	recalculate()
