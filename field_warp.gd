extends Warp
class_name FieldWarp

@export_node_path("FieldWarp") var target_path
@onready var target : FieldWarp = get_node(target_path)


func _ready():
	offset = target.position - position
	
	var dir := Vector2(0.0, -1.0).rotated(rotation + PI)
	angle = (rotation - target.rotation) / (dir.y - dir.x)
