extends CharacterBody2D
class_name Player

@onready var hit_box := $CollisionShape2D
@onready var view_cone := $ViewCone

@export var move_speed := 50
@export var rotate_speed := PI/3
@export var fov := PI/6
@export var far_plane := 300.0

const view_cone_image_size := Vector2i(768, 512) 


func _ready():
	view_cone.scale = Vector2(tan(fov) * far_plane / (view_cone_image_size.x / 2), far_plane / view_cone_image_size.y)
	

func _draw():
	draw_circle(Vector2(), hit_box.shape.radius, Color.BLACK)


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
