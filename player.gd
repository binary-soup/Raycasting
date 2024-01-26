extends CharacterBody2D
class_name Player

signal physics_changed

@onready var hit_box := $CollisionShape2D
@onready var view_cone := $ViewCone

@export var walk_speed := 30.0
@export var sprint_speed := 50.0

@export var mouse_sensitivity := 0.215
@export var fov := PI/4

@export var far_plane := 20.0 :
	set(val):
		far_plane = val
		
		var cone_size : Vector2 = view_cone.texture.get_size()
		view_cone.scale = Vector2(tan(fov) * val / (cone_size.x / 2), val / cone_size.y) * Constants.TILEMAP_CELL_SIZE


func _draw():
	draw_circle(Vector2(), hit_box.shape.radius, Color.BLACK)


func _physics_process(delta : float):
	velocity = Vector2()
	var rotate_amount := Main.MOUSE_MOTION * mouse_sensitivity
	
	rotation += rotate_amount.x * delta
	var up := Vector2.UP.rotated(rotation)
	var left := Vector2.LEFT.rotated(rotation)
	
	if Input.is_action_pressed("move_forward"):
		velocity = up * _choose_speed()
	elif Input.is_action_pressed("move_back"):
		velocity = -up * walk_speed
	elif Input.is_action_pressed("move_left"):
		velocity = left * walk_speed
	elif Input.is_action_pressed("move_right"):
		velocity = -left * walk_speed

	move_and_slide()
	
	if velocity != Vector2() or rotate_amount.x != 0.0:
		emit_signal("physics_changed")


func _choose_speed() -> float:
	if Input.is_action_pressed("sprint"):
		return sprint_speed
	else:
		return walk_speed


func get_origin() -> Vector2:
	return position / Constants.TILEMAP_CELL_SIZE

