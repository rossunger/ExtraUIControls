extends Control

signal close_requested
signal option_selected(option:String)

@export var options = ["asc","desc"]
@export var close_on_select = true

func _ready():
	for option in options:
		var button = Button.new()
		button.text = option
		button.pressed.connect(option_selected.emit.bind(option))		
		if close_on_select:
			button.pressed.connect(close_requested.emit)
		%sort_button_container.add_child(button)
