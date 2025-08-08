extends Control

var button_group := ButtonGroup.new()

func _ready():
	for child in get_children():
		if child is Button:
			child.toggle_mode = true
			child.button_group = button_group
		
