extends ColorRect
class_name DebugMenu


func _on_normal_mapping_toggled(val : bool):
	get_tree().call_group("DebugOptions", "_on_normal_mapping_toggled", val)


func _on_parallax_mapping_toggled(val : bool):
	get_tree().call_group("DebugOptions", "_on_parallax_mapping_toggled", val)


func _on_far_plane_value_changed(val : float):
	get_tree().call_group("DebugOptions", "_on_far_plane_value_changed", val)
