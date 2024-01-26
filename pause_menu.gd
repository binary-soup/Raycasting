extends ColorRect
class_name PauseMenu

@export var paused : bool:
	get:
		return paused
	set(val):
		paused = val
		visible = val
		get_tree().paused = val
		
		if val:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _ready():
	paused = false


func _unhandled_input(_event):
	if Input.is_action_just_pressed("pause"):
		paused = !paused


func _on_resume_button_pressed():
	paused = false


func _on_quit_button_pressed():
	get_tree().quit()
