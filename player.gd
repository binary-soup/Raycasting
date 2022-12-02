extends CharacterBody2D
class_name Player

@export var move_speed := 50
@export var rotate_speed := 2*PI/3

var dir := Vector2.UP


func _draw():
	draw_circle(Vector2(), 5, Color.BLACK)
	draw_line(Vector2(), Vector2.UP * 20, Color.WEB_PURPLE, 2.0)


func _process(delta : float):
	velocity = Vector2()
	
	if Input.is_action_pressed("rotate_left"):
		rotation -= rotate_speed * delta
	elif Input.is_action_pressed("rotate_right"):
		rotation += rotate_speed * delta
	
	dir = Vector2.UP.rotated(rotation)
	
	if Input.is_action_pressed("move_forward"):
		velocity = dir * move_speed
	elif Input.is_action_pressed("move_back"):
		velocity = dir * -move_speed

	move_and_slide()
