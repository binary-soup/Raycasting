extends Control
class_name Main

static var MOUSE_MOTION : Vector2
var mazes : Array[PackedScene] = [
	preload("res://maze_v1.tscn"),
	preload("res://maze_v2.tscn")
]

@onready var game := $MiniMap/Game
@export_range(1, 2) var maze_variant := 1


func _ready():
	var maze : Maze = mazes[maze_variant - 1].instantiate()
	game.add_child(maze)
	$Canvas.maze = maze


func _process(_delta):
	MOUSE_MOTION = Vector2()
	
	if Input.is_action_just_pressed("show_mini_map"):
		$MiniMap.visible = !$MiniMap.visible


func _input(event : InputEvent):
	if event is InputEventMouseMotion:
		MOUSE_MOTION = (event as InputEventMouseMotion).relative


# AlwaysProcess group
func _on_always_process():
	game.position = get_viewport_rect().get_center()
