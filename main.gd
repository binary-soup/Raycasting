extends Control
class_name Main

static var MOUSE_MOTION : Vector2


func _process(_delta):
	MOUSE_MOTION = Vector2()


func _input(event : InputEvent):
	if event is InputEventMouseMotion:
		MOUSE_MOTION = (event as InputEventMouseMotion).relative
