extends Warp
class_name FieldWarp

@export_node_path("FieldWarp") var target_path
@onready var target : FieldWarp = get_node(target_path)


func _ready():
	offset = (target.position - position) / Constants.TILEMAP_CELL_SIZE
	
	var normal := Vector2.DOWN.rotated(rotation)
	var target_normal := Vector2.DOWN.rotated(target.rotation)
	
	angle = (rotation - target.rotation + PI * normal.dot(target_normal))
