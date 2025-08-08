@tool 
extends Control

signal page_changed

@export var page_count = 3
@export var current_page = 2
@export_category("Style")
@export var h_separation = 4:
	set(val):
		h_separation = val
		%pagination_hbox.add_theme_constant_override("separation",val)
		$HBoxContainer.add_theme_constant_override("separation",val)
@export var min_size_x = 32: 
	set(val): 
		min_size_x = val
		set_min_size_x()
		for child in %pagination_hbox.get_children():
			child.custom_minimum_size.x = val
			child.size.x = val
			
@export var first_icon: Texture2D:
	set(val): 
		first_icon = val
		set_icons()
@export var previous_icon: Texture2D:
	set(val): 
		previous_icon = val
		set_icons()
@export var next_icon: Texture2D:
	set(val): 
		next_icon = val
		set_icons()
@export var last_icon: Texture2D:
	set(val): 
		last_icon = val
		set_icons()

func _ready():					
	if not Engine.is_editor_hint():
		connect_signals()
	init_pagination()

func set_icons():
	if first_icon:
		%go_to_first_button.icon = first_icon		
		%go_to_first_button.text = ""
	else:
		%go_to_first_button.text = "<<"
	if previous_icon:
		%go_to_previous_button.icon = previous_icon			
		%go_to_previous_button.text = ""		
	else:
		%go_to_previous_button.text = "<"
	if next_icon	:	
		%go_to_next_button.icon = next_icon				
		%go_to_next_button.text = ""
	else:
		%go_to_next_button.text = ">"
	if last_icon:
		%go_to_last_button.icon = last_icon	
		%go_to_last_button.text = ""
	else:
		%go_to_last_button.text = ">>"	
		
func set_min_size_x():
	%go_to_first_button.custom_minimum_size.x = min_size_x
	%go_to_previous_button.custom_minimum_size.x = min_size_x	
	%go_to_next_button.custom_minimum_size.x = min_size_x		
	%go_to_last_button.custom_minimum_size.x = min_size_x			
	
func connect_signals():	
	%go_to_first_button.pressed.connect(func():		
		current_page = 0
		page_changed.emit(current_page)
		%go_to_first_button.release_focus()
	)	
	%go_to_previous_button.pressed.connect(func():
		current_page -= 1	
			
		page_changed.emit(current_page)
		%go_to_previous_button.release_focus()
	)	
	%go_to_next_button.pressed.connect(func():
		current_page += 1
		page_changed.emit(current_page)
		%go_to_next_button.release_focus()		
	)	
	%go_to_last_button.pressed.connect(func():
		current_page = page_count-1
		page_changed.emit(current_page)	
		%go_to_last_button.release_focus()		
			
	)	
	page_changed.connect(on_page_changed)

func get_theme_variation_base_name():
	return theme_type_variation if theme_type_variation else owner.theme_type_variation if owner and owner.theme_type_variation else ""

func init_pagination():	
	var base_name = get_theme_variation_base_name()
	%go_to_first_button.theme_type_variation =  base_name + "_" + "navigation_button"
	%go_to_previous_button.theme_type_variation = base_name + "_" + "navigation_button"
	%go_to_next_button.theme_type_variation = base_name + "_" + "navigation_button"
	%go_to_last_button.theme_type_variation = base_name + "_" + "navigation_button"
	
	var hbox = %pagination_hbox
	while hbox.get_child_count() > page_count:
		var child = hbox.get_child(-1)
		hbox.remove_child(child)
		child.queue_free()
	while hbox.get_child_count() < page_count:
		var page_button = Button.new()
		page_button.toggle_mode = true
		page_button.text = str(1+hbox.get_child_count())		
		page_button.custom_minimum_size.x = min_size_x
		page_button.size.x = min_size_x
		page_button.theme_type_variation = get_theme_variation_base_name() + "_" + "page_button"
		page_button.toggled.connect(func(on):
			current_page = page_button.get_index()
			page_changed.emit(current_page)	
			page_button.release_focus()
		)
		hbox.add_child(page_button)	
		if page_button.get_index() == current_page: page_button.disabled = true
		
func on_page_changed(id):	
	%go_to_first_button.disabled = id == 0
	%go_to_previous_button.disabled = id == 0	
	%go_to_next_button.disabled = id == page_count-1
	%go_to_last_button.disabled = id == page_count-1
	for button in %pagination_hbox.get_children():
		button.disabled = button.get_index() == id
		if button.disabled:
			button.set_pressed_no_signal(true)
		else:
			button.set_pressed_no_signal(false)
			
			
