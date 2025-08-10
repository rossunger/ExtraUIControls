extends Control
signal option_selected
@export var max_visible_options = 10
@export var options = "#Colors\nRed\nblue\ngreen\n#Other\nnoooo\naasfv\nafvd\nvdf\nadv\awer\naaaaa\nacadcad\nadcad"
@export var allow_multiple = false
@export var allow_search = false
@export var allow_filter = false
@export var show_scroll_buttons = true
@export var font_size = 16

@onready var clear_selection_button = %clear_selection_button
@onready var options_button = %popup_button
@onready var options_container = %OptionsContainer
@onready var options_container_clipper = %OptionsContainerClipper
@onready var options_popup = %options_popup
@onready var options_popup_window = %options_popup_window

var selected_options = []

var touched_option: Button
var possibly_dragging = false
var dragging = false
const DRAG_DELAY = .125
var drag_timer = Timer.new()
var scroll_direction = 0

var first_popup = true

func _ready():
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root().is_ancestor_of(self):
		return
	add_child(drag_timer)
	drag_timer.timeout.connect(toggle_button_from_selection)
	options_popup_window.visible = false
	options_container.gui_input.connect(options_container_input)
	options_container_clipper.resized.connect(func():
		options_container.custom_minimum_size.x = options_container_clipper.size.x
		options_container.size.x = options_container.custom_minimum_size.x
	)
	options_button.toggled.connect(func(on):
		toggle_options_window(on)
	)
	if allow_search:
		%search.text_changed.connect(filter_options)
	if show_scroll_buttons:
		%up_button.mouse_entered.connect(func(): scroll_direction = -1)
		%up_button.mouse_exited.connect(func(): if scroll_direction == -1: scroll_direction = 0)
		%down_button.mouse_entered.connect(func(): scroll_direction = 1)
		%down_button.mouse_exited.connect(func(): if scroll_direction == 1: scroll_direction = 0)
		clear_selection_button.pressed.connect(func():
			for button in selected_options:
				button.icon = null
			selected_options.clear()
			update_selection_text()
			option_selected.emit([])
		)
	%up_button.visible = show_scroll_buttons
	%down_button.visible = show_scroll_buttons
	
	options_popup_window.focus_exited.connect(func():
		if not options_button.get_global_rect().has_point(get_viewport().get_mouse_position()):
			options_button.button_pressed = false
	)
	
	%up_button.theme_type_variation = theme_type_variation + "_scroll_buttons"
	%down_button.theme_type_variation = theme_type_variation + "_scroll_buttons"
	options_popup.theme_type_variation = theme_type_variation + "_panel"
	options_button.theme_type_variation = theme_type_variation + "_toggle_button"
	options_container.theme_type_variation = theme_type_variation + "_options_vbox"
	%search.theme_type_variation = theme_type_variation + "_search"
		
	set_options(options)
	update_selection_text()
	
func filter_options(text):
	for option in options_container.get_children():
		if option.disabled: continue
		option.visible = option.text.containsn(text) or text.is_empty()
	
func toggle_options_window(on):
	options_popup_window.visible = on
	if on:
		var new_size_x = %options_button_hbox.size.x
		custom_minimum_size.x = new_size_x
		options_popup.custom_minimum_size.x = new_size_x
		options_popup.size.x = new_size_x
		options_popup_window.size = options_popup.size
		options_popup_window.position.x = global_position.x
		var ideal_size_y = get_ideal_size_y()
		if should_display_below(ideal_size_y):
			options_popup_window.position.y = options_button.global_position.y + options_button.size.y # - options_button.size.y/2 + 2
			options_popup_window.size.y = clamp(ideal_size_y, font_size, get_viewport_rect().size.y - global_position.y)
		else:
			options_popup_window.size.y = ideal_size_y # clamp( ideal_size_y, font_size, global_position.y)
			options_popup_window.position.y = options_button.global_position.y - options_popup_window.size.y
		options_popup.size.y = options_popup_window.size.y
		if not allow_multiple and len(selected_options) == 1:
			scroll_to_button(selected_options[0])
		if first_popup:
			first_popup = false
			toggle_options_window.call_deferred(true)
		
func get_ideal_size_y() -> int:
	if options_container.get_child_count() == 0: return 0
	var node: Control = options_container.get_child(max(0, max_visible_options))
	var delta = node.position.y - options_container_clipper.size.y
	return options_popup.size.y + delta # max( options_container.get_child_count() * font_size*2, font_size)
	
	
func should_display_below(ideal_size):
	var space_available_below = get_viewport_rect().size.y - global_position.y + options_button.size.y
	var space_available_above = global_position.y
	if ideal_size < space_available_below: return max(space_available_above, space_available_below) == space_available_below
	if ideal_size > space_available_above: return max(space_available_above, space_available_below) == space_available_below
	return false
	
func set_options(new_options):
	options = new_options.split("\n")
	for child in options_container.get_children():
		options_container.remove_child(child)
		child.queue_free()
	for option in options:
		var button := Button.new()
		if option.begins_with("#"):
			button.disabled = true

			button.text = option.trim_prefix("#")
			button.theme_type_variation = owner.theme_type_variation + "_" + "option_heading_button"
		else:
			button.text = option
			button.theme_type_variation = owner.theme_type_variation + "_" + "option_button"
			button.gui_input.connect(option_input.bind(button))
			button.add_theme_constant_override("icon_max_width", font_size)
		button.focus_mode = Control.FOCUS_NONE
		button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		options_container.add_child(button)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.x += 32
		button.add_theme_font_size_override("font_size", font_size)
		button.mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size.x = options_container.size.x
	
func option_input(event: InputEvent, who: Button):
	if event is InputEventScreenTouch and event.pressed:
		touched_option = who
		drag_timer.start(DRAG_DELAY)
		
func update_selection_text():
	var new_text = ", ".join(selected_options.map(func(a): return a.text))
	options_button.text = new_text if not new_text.is_empty() else "(select)"
	options_button.tooltip_text = options_button.text
	option_selected.emit(selected_options.map(func(a): return a.text))
	clear_selection_button.visible = len(selected_options) != 0 and allow_multiple
		
func toggle_button_from_selection():
	if not touched_option in selected_options:
		if not allow_multiple:
			for old_selection in selected_options:
				old_selection.icon = null
				selected_options.erase(old_selection)
		selected_options.push_back(touched_option)
		touched_option.icon = preload("icons/icon_tick.svg")
	else:
		selected_options.erase(touched_option)
		touched_option.icon = null
	update_selection_text()
	drag_timer.stop()
	if not allow_multiple:
		options_button.button_pressed = false
		
func get_max_scroll_y():
	return -options_container.size.y + options_container_clipper.size.y
	
func options_container_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		options_container.position.y = clamp(options_container.position.y + font_size, get_max_scroll_y(), 0)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		options_container.position.y = clamp(options_container.position.y - font_size, get_max_scroll_y(), 0)
	
	if event is InputEventScreenTouch:
		possibly_dragging = event.pressed
		if not possibly_dragging and dragging and touched_option:
			touched_option.remove_theme_stylebox_override("normal")
			touched_option = null
		dragging = false
		
	if event is InputEventScreenDrag:
		options_container.position.y = clamp(options_container.position.y + event.relative.y, get_max_scroll_y(), 0)
		if event.relative.length() > 2:
			dragging = true
			drag_timer.stop()

func scroll_to_button(who):
	options_container.position.y = clamp(-who.position.y, get_max_scroll_y(), 0)

func _physics_process(delta):
	if scroll_direction > 0:
		options_container.position.y = clamp(options_container.position.y - delta * 10 * font_size, get_max_scroll_y(), 0)
	elif scroll_direction < 0:
		options_container.position.y = clamp(options_container.position.y + delta * 10 * (font_size), get_max_scroll_y(), 0)

func _input(event):
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root().is_ancestor_of(self):
		return
	if event is InputEventScreenTouch and event.pressed:
		if not options_popup_window.get_visible_rect().has_point(event.position):
			if not options_button.get_global_rect().has_point(event.position):
				options_button.button_pressed = false
