extends Control
class_name Main

static var MOUSE_MOTION : Vector2


func _process(_delta):
	MOUSE_MOTION = Vector2()
	
	if Input.is_action_just_pressed("show_mini_map"):
		$MiniMap.visible = !$MiniMap.visible


func _input(event : InputEvent):
	if event is InputEventMouseMotion:
		MOUSE_MOTION = (event as InputEventMouseMotion).relative


# AlwaysProcess group
func _on_always_process():
	$MiniMap/Game.position = get_viewport_rect().get_center()
