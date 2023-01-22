extends CharacterBody2D
class_name Player

signal physics_changed

@onready var hit_box := $CollisionShape2D
@onready var view_cone := $ViewCone

@export var move_speed := 50
@export var rotate_speed := PI/3
@export var fov := PI/4
@export var far_plane := 300.0


func _ready():
	var cone_size : Vector2 = view_cone.texture.get_size()
	view_cone.scale = Vector2(tan(fov) * far_plane / (cone_size.x / 2), far_plane / cone_size.y)
	

func _draw():
	draw_circle(Vector2(), hit_box.shape.radius, Color.BLACK)


func _physics_process(delta : float):
	velocity = Vector2()
	var rotate_amount := 0.0
	
	if Input.is_action_pressed("rotate_left"):
		rotate_amount = -rotate_speed * delta
	elif Input.is_action_pressed("rotate_right"):
		rotate_amount = rotate_speed * delta
	
	rotation += rotate_amount
	var dir := Vector2.UP.rotated(rotation)
	
	if Input.is_action_pressed("move_forward"):
		velocity = dir * move_speed
	elif Input.is_action_pressed("move_back"):
		velocity = dir * -move_speed

	move_and_slide()
	
	if velocity == Vector2() and rotate_amount == 0.0:
		return
		
	emit_signal("physics_changed")
