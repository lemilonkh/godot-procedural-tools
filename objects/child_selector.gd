tool
extends Spatial

export(Array, float, 0, 1) var child_probabilities = []
export(float, 0, 1) var child_selection = 0 setget set_selected_child, get_selected_child 
export(bool) var is_random = true setget set_random

var selected_child = null

func _init():
	update()

func set_random(enabled: bool):
	is_random = enabled
	update()

func update():
	if is_random:
		child_selection = randf()
	
	choose_child(child_selection)

func choose_child(selection):
	var current_selection = child_selection

	var child_index = 0
	for child in get_children():
		var probability = child_probabilities[child_index]

		if current_selection >= probability:
			select_child(child, child_index)
			break
		else:
			current_selection -= probability
			
		child_index += 1

func select_child(new_child, child_index):
	for child in get_children():
		if child != new_child:
			child.set_visible(false)

	selected_child = new_child
	new_child.set_visible(true)

func set_selected_child(selection):
	child_selection = selection
	choose_child(selection)

func get_selected_child():
	return child_selection
