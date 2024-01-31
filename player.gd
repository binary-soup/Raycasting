extends CharacterBody2D
class_name Player

signal physics_changed

var prev_view_angle : Vector2
var prev_step_dir := 1.0

var view_dir := Vector2()

var displacement := 0.0
var step_sounds : Bag

@onready var hit_box := $CollisionShape2D
@onready var view_cone := $ViewCone
@onready var footsteps := $Footsteps

@export var acceleration := 5.0
@export var walk_speed := 30.0
@export var strafe_speed := 20.0
@export var sprint_speed := 50.0

@export var mouse_sensitivity := 0.215
@export var fov := PI/4

@export var clamp_pitch := true
@export var pitch_clamp := PI/24

@export var use_view_bobbing := true
@export var view_bob_fov := PI/256
@export var step_factor := 0.25

@export var far_plane := 20.0 :
	set(val):
		far_plane = val
		
		var cone_size : Vector2 = view_cone.texture.get_size()
		view_cone.scale = Vector2(tan(fov) * val / (cone_size.x / 2), val / cone_size.y) * Constants.TILEMAP_CELL_SIZE

var pitch := 0.0
var view_angle := Vector2():
	get:
		return Vector2(rotation, pitch)
	set(val):
		rotation = val.x
		pitch = val.y


func _ready():
	_load_step_sounds()


func _load_step_sounds():
	var data := []
	for i in range(12):
		data.append(load("res://assets/sfx/stone_step_%d.wav" % [i+1]))
	
	step_sounds = Bag.new(data)


func _draw():
	draw_circle(Vector2(), hit_box.shape.radius, Color.BLACK)


func _physics_process(delta : float):
	_handle_movement(delta)
	_handle_view(delta)
	_handle_step_sounds()
	
	if !velocity.is_zero_approx() or view_angle != prev_view_angle:
		emit_signal("physics_changed")


func _handle_view(delta : float):
	prev_view_angle = view_angle
	
	var extents := PI/2
	if clamp_pitch: extents = pitch_clamp
	
	view_dir += Main.MOUSE_MOTION * mouse_sensitivity * delta
	view_dir.y = clamp(view_dir.y, -extents, extents)
	
	var view_bob := Vector2()
	if use_view_bobbing:
		view_bob = Vector2(0.0, sin(displacement * step_factor)) * view_bob_fov
	
	view_angle = view_bob + view_dir


func _handle_step_sounds():
	var factor := step_factor * 0.8
	var step := cos(displacement * factor) * factor
	
	if sign(step) == prev_step_dir:
		return
	
	prev_step_dir = sign(step)
	
	footsteps.stream = step_sounds.choose()
	footsteps.play()


func _handle_movement(delta : float):
	var target := _target_velocity()
	var diff := target - velocity
	
	if acceleration >= diff.length():
		velocity = target
	else:
		velocity += diff.normalized() * acceleration
	
	displacement += velocity.length() * delta
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


# DebugOptions group
func _on_use_player_view_bobbing_toggled(val : bool):
	use_view_bobbing = val
