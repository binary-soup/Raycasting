extends Node2D
class_name MultiWarp


func get_warps() -> Array:
	return get_children()


func _ready():
	for warp in get_warps():
		warp.transform = transform * warp.transform
	
	for warp in get_warps():
		warp.recalculate()
	
	transform = Transform2D.IDENTITY
