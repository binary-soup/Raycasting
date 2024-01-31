extends Resource
class_name Bag

var items := []
var bag := []


func _init(data : Array):
	items.append_array(data)
	bag.append_array(data)


func choose() -> Variant:
	var item = bag[randi() % bag.size()]
	bag.erase(item)
	
	if bag.is_empty():
		bag.append_array(items)
		bag.erase(item)
	
	return item
