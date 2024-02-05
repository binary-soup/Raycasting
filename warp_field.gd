extends Node2D
class_name WarpField

@export_node_path("WarpField") var target_path
@onready var target : WarpField = get_node(target_path)

var dir : Vector2
var offset : Vector2
var angle : float


func get_coords() -> Vector2i:
	return Vector2i((position / Constants.TILEMAP_CELL_SIZE).floor())


func _ready():
	dir = Vector2(0.0, -1.0).rotated(rotation)
	offset = target.position - position
	angle = rotation - target.rotation
