extends ColorRect
class_name DebugMenu


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
