extends Control
signal up
signal down

func _ready():
	%previous_button.pressed.connect(up.emit)	
	%next_button.pressed.connect(down.emit)	
	%previous_button.pressed.connect(%previous_button.release_focus)
	%next_button.pressed.connect(%next_button.release_focus)
	%previous_button.resized.connect(func():%previous_button.custom_minimum_size.x = %previous_button.size.y)
	%next_button.resized.connect(func():	%next_button.custom_minimum_size.x = %next_button.size.y)	
	if %previous_button.has_theme_icon("icon"):
		%previous_button.icon = null
	if %next_button.has_theme_icon("icon"):
		%next_button.icon = null
	if not theme_type_variation:
		theme_type_variation = owner.theme_type_variation + "_" + "spinbox_buttons_control"
	if not $VBoxContainer.theme_type_variation:
		$VBoxContainer.theme_type_variation = theme_type_variation + "_" + "_vbox"
	if not %next_button.theme_type_variation:
		%next_button.theme_type_variation = theme_type_variation + "_" + "up_button"
	if not %previous_button.theme_type_variation:
		%previous_button.theme_type_variation = theme_type_variation + "_" + "down_button"
	
