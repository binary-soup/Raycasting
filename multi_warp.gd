extends Node2D
class_name MultiWarp


func get_warps() -> Array:
	return get_children()


func _ready():
	for warp in get_children():
		_update_warp(warp)

	for warp in get_children():
		warp.recalculate()

	position = Vector2()
	rotation = 0.0


func _update_warp(warp : Warp):
	warp.position += position
	warp.rotation += rotation
