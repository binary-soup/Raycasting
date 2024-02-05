extends Area2D
class_name WarpField

@export_node_path("WarpField") var target_path
@onready var target : WarpField = get_node(target_path)

@onready var shape : RectangleShape2D = $CollisionShape2D.shape


func _on_area_entered(area : Area2D):
	var body : CharacterBody2D = area.get_parent()
	var dir := Vector2(0.0, -1.0).rotated(target.rotation + PI)
	
	body.position = target.position + (body.position - position) + dir * (shape.size.x + 2.0)
