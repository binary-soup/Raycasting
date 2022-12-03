extends CharacterBody2D
class_name Player

@export var move_speed := 50
@export var rotate_speed := PI/3
@export var fov := PI/6
@export var far_plane := 300.0


func _draw():
	var c := Color.YELLOW
	c.a = 0.5
	
	var z := far_plane * tan(fov)
	draw_colored_polygon([Vector2(), Vector2(-z, -far_plane), Vector2(z, -far_plane)], c)
	
	draw_circle(Vector2(), 5, Color.BLACK)


func _process(delta : float):
	velocity = Vector2()
	
	if Input.is_action_pressed("rotate_left"):
		rotation -= rotate_speed * delta
	elif Input.is_action_pressed("rotate_right"):
		rotation += rotate_speed * delta
	
	var dir := Vector2.UP.rotated(rotation)
	
	if Input.is_action_pressed("move_forward"):
		velocity = dir * move_speed
	elif Input.is_action_pressed("move_back"):
		velocity = dir * -move_speed

	move_and_slide()
