extends ColorRect
class_name PauseMenu

@export var paused : bool:
	get:
		return paused
	set(val):
		paused = val
		visible = val
		get_tree().paused = paused


func _ready():
	paused = false


func _unhandled_input(_event):
	if Input.is_action_just_pressed("pause"):
		paused = !paused
