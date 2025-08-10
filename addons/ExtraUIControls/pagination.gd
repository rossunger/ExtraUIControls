@tool
extends Control

signal page_changed

@export var page_count = 3:
	set = set_page_count
@export var current_page = 2
@export_category("Style")
@export var h_separation = 4:
	set = set_h_separation
@export var min_size_x = 32:
	set = set_min_size_x
@export var first_icon: Texture2D:
	set(val):
		if first_icon == val: return
		first_icon = val
		if not is_node_ready(): return
		set_icons()
@export var previous_icon: Texture2D:
	set(val):
		if previous_icon == val: return
		previous_icon = val
		if not is_node_ready(): return
		set_icons()
@export var next_icon: Texture2D:
	set(val):
		if next_icon == val: return
		next_icon = val
		if not is_node_ready(): return
		set_icons()
@export var last_icon: Texture2D:
	set(val):
		if last_icon == val: return
		last_icon = val
		if not is_node_ready(): return
		set_icons()

func _ready():
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root().is_ancestor_of(self):
		return
	connect_signals()
	init_pagination()
	
func set_page_count(val):
	if page_count == val: return
	page_count = val
	if not is_node_ready(): return
	var hbox = %pagination_hbox
	while hbox.get_child_count() > page_count:
		var child = hbox.get_child(-1)
		hbox.remove_child(child)
		child.queue_free()
	while hbox.get_child_count() < page_count:
		var page_button = Button.new()
		page_button.toggle_mode = true
		page_button.text = str(1 + hbox.get_child_count())
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

func set_h_separation(val):
	if h_separation == val: return
	h_separation = val
	if not is_node_ready(): return
	if h_separation >= 0:
		%pagination_hbox.add_theme_constant_override("separation", h_separation)
		$HBoxContainer.add_theme_constant_override("separation", h_separation)
	else:
		if %pagination_hbox.has_theme_constant_override("separation"):
			remove_theme_constant_override("separation")
		if $HBoxContainer.has_theme_constant_override("separation"):
			remove_theme_constant_override("separation")
		var base_name = get_theme_variation_base_name()
		%pagination_hbox.theme_type_variation = base_name + "_" + "hbox"
		%HBoxContainer.theme_type_variation = base_name + "_" + "hbox"


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
	if next_icon:
		%go_to_next_button.icon = next_icon
		%go_to_next_button.text = ""
	else:
		%go_to_next_button.text = ">"
	if last_icon:
		%go_to_last_button.icon = last_icon
		%go_to_last_button.text = ""
	else:
		%go_to_last_button.text = ">>"
		
func set_min_size_x(val):
	if min_size_x == val: return
	min_size_x = val
	if not is_node_ready(): return
	%go_to_first_button.custom_minimum_size.x = min_size_x
	%go_to_previous_button.custom_minimum_size.x = min_size_x
	%go_to_next_button.custom_minimum_size.x = min_size_x
	%go_to_last_button.custom_minimum_size.x = min_size_x
	for child in %pagination_hbox.get_children():
		child.custom_minimum_size.x = val
		child.size.x = val
		
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
		current_page = page_count - 1
		page_changed.emit(current_page)
		%go_to_last_button.release_focus()
			
	)
	page_changed.connect(on_page_changed)

func get_theme_variation_base_name():
	return theme_type_variation if theme_type_variation else owner.theme_type_variation if owner and owner.theme_type_variation else ""

func init_pagination():
	var base_name = get_theme_variation_base_name()
	%go_to_first_button.theme_type_variation = base_name + "_" + "navigation_button"
	%go_to_previous_button.theme_type_variation = base_name + "_" + "navigation_button"
	%go_to_next_button.theme_type_variation = base_name + "_" + "navigation_button"
	%go_to_last_button.theme_type_variation = base_name + "_" + "navigation_button"
	
	set_page_count(page_count)
	set_h_separation(h_separation)
	set_icons()
	set_min_size_x(min_size_x)

func on_page_changed(id):
	%go_to_first_button.disabled = id == 0
	%go_to_previous_button.disabled = id == 0
	%go_to_next_button.disabled = id == page_count - 1
	%go_to_last_button.disabled = id == page_count - 1
	for button in %pagination_hbox.get_children():
		button.disabled = button.get_index() == id
		if button.disabled:
			button.set_pressed_no_signal(true)
		else:
			button.set_pressed_no_signal(false)
