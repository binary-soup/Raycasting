extends Node2D
class_name Warp

var offset := Vector2()
var angle := 0.0


func get_coords() -> Vector2i:
	return Vector2i((position / Constants.TILEMAP_CELL_SIZE).floor())


func calc_normal(pos : Vector2) -> Vector2:
	var diff := pos - position
	
	if abs(diff.x) >= abs(diff.y):
		diff.y = 0.0
	else:
		diff.x = 0.0
	
	return diff.normalized()
