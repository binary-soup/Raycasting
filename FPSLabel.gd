extends Label
class_name FPSLabel


func _process(delta : float):
	text = "Delta: %f ms, FPS: %f" % [delta * 1000, 1 / delta]
