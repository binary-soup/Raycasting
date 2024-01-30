extends CharacterBody2D
class_name Player

signal physics_changed

var pitch := 0.0

@onready var hit_box := $CollisionShape2D
@onready var view_cone := $ViewCone

@export var acceleration := 5.0
@export var walk_speed := 30.0
@export var strafe_speed := 20.0
@export var sprint_speed := 50.0

@export var mouse_sensitivity := 0.215
@export var fov := PI/4

@export var clamp_pitch := true
@export var pitch_clamp := PI/24

@export var far_plane := 20.0 :
	set(val):
		far_plane = val
		
		var cone_size : Vector2 = view_cone.texture.get_size()
		view_cone.scale = Vector2(tan(fov) * val / (cone_size.x / 2), val / cone_size.y) * Constants.TILEMAP_CELL_SIZE


func _draw():
	draw_circle(Vector2(), hit_box.shape.radius, Color.BLACK)


func _physics_process(delta : float):
	var rotate_amount := Main.MOUSE_MOTION * mouse_sensitivity
	rotation += rotate_amount.x * delta
	
	var extents := PI/2
	if clamp_pitch: extents = pitch_clamp
	
	pitch = clamp(pitch + rotate_amount.y * delta, -extents, extents)
	
	_handle_movement()
	
	if !velocity.is_zero_approx() or !rotate_amount.is_zero_approx():
		emit_signal("physics_changed")


func _handle_movement():
	var target := _target_velocity()
	var diff := target - velocity
	
	if acceleration >= diff.length():
		velocity = target
	else:
		velocity += diff.normalized() * acceleration

	move_and_slide()


func _target_velocity() -> Vector2:
	var target := Vector2()
	
	if Input.is_action_pressed("move_forward"):
		target.y -= 1
	if Input.is_action_pressed("move_back"):
		target.y += 1
	target.y *= _choose_speed()
		
	if Input.is_action_pressed("move_left"):
		target.x -= 1
	if Input.is_action_pressed("move_right"):
		target.x += 1
	target.x *= strafe_speed
	
	return target.rotated(rotation)


func _choose_speed() -> float:
	if Input.is_action_pressed("move_forward") and Input.is_action_pressed("sprint"):
		return sprint_speed
	else:
		return walk_speed


func get_origin() -> Vector2:
	return position / Constants.TILEMAP_CELL_SIZE


# DebugOptions group
func _on_clamp_player_pitch_toggled(val : bool):
	clamp_pitch = val
