extends ColorRect
class_name DebugMenu

@onready var normal_mapping := $CenterContainer/VBoxContainer/NormalMapping
@onready var parallax_mapping := $CenterContainer/VBoxContainer/ParallaxMapping
@onready var far_plane := $CenterContainer/VBoxContainer/FarPlane
@onready var clamp_pitch := $CenterContainer/VBoxContainer/ClampPitch
@onready var view_bobbing := $CenterContainer/VBoxContainer/ViewBobbing


func _ready():
	_on_normal_mapping_toggled(normal_mapping.button_pressed)
	_on_parallax_mapping_toggled(parallax_mapping.button_pressed)
	far_plane.value = far_plane.max_value
	_on_clamp_pitch_toggled(clamp_pitch.button_pressed)
	_on_view_bobbing_toggled(view_bobbing.button_pressed)


func _on_normal_mapping_toggled(val : bool):
	get_tree().call_group("DebugOptions", "_on_normal_mapping_toggled", val)


func _on_parallax_mapping_toggled(val : bool):
	get_tree().call_group("DebugOptions", "_on_parallax_mapping_toggled", val)


func _on_far_plane_value_changed(val : float):
	get_tree().call_group("DebugOptions", "_on_far_plane_value_changed", val)


func _on_clamp_pitch_toggled(val : bool):
	get_tree().call_group("DebugOptions", "_on_clamp_player_pitch_toggled", val)


func _on_view_bobbing_toggled(val: bool):
	get_tree().call_group("DebugOptions", "_on_use_player_view_bobbing_toggled", val)
