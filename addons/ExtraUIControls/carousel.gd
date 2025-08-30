#@tool
extends Control

signal item_tapped(index: int)
signal item_selected(index: int)

@export var spacing: int = -1
@export var animation_speed: float = 0.3
@export var visible_count: int = 1
@export var enable_buttons: bool = true
@export var enable_touch: bool = true
@export var align_center: bool = true
@export var loop: bool = true
@export var expand_children_vertically: bool = false
@export var show_dots := true
@export var dots_numbered := false
@export var disabled = false
@export var init_on_ready = true
var _nav_controls = []

var _items: Array[Control] = []
var _clones: Array[Control] = []
var _container: HBoxContainer
var _tween: Tween

var _current_index: int = 0:
	set(val):	
		if _container and _container.get_child_count() > _current_index:
			var old_child = _container.get_child(_current_index)
			old_child.theme_type_variation = theme_type_variation + "_item"			
			old_child.z_index = 0				
		_current_index = val
		item_selected.emit(_real_index(val))
		if show_dots:
			var child_count = dots_hbox._container.get_child_count()
			if child_count > val:
				for i in child_count:
					dots_hbox._container.get_child(i).set_pressed_no_signal(i == val)
		#var item = get_child(_real_index(val))
		#if item is Control and item.focus_mode == FOCUS_ALL: 
		#	item.grab_focus()
		if _container and _container.get_child_count() > _current_index and _current_index != -1:
			var new_child = _container.get_child(_current_index)
			new_child.theme_type_variation = theme_type_variation + "_item_selected"
			new_child.z_index = 1
		
var _touch_active: bool = false
var _positions: Array[float]

# Drag variables
var _is_dragging: bool = false
var _touch_start_pos: Vector2

var _dot_buttons = []
var dots_hbox: Control
var nav_buttons_queue := []

func _ready() -> void:
	#if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root().is_ancestor_of(self):
	#	return		
	_container = HBoxContainer.new()
	_nav_controls.push_back(_container)
	_container.grow_horizontal = Control.GrowDirection.GROW_DIRECTION_BOTH
	_container.anchor_right = 1.0
	_container.anchor_bottom = 1.0
	_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_container)
	_container.theme_type_variation = theme_type_variation + "_hbox"
	if spacing > -1:
		_container.add_theme_constant_override("separation", spacing)
	else:
		spacing = _container.get_theme_constant("separation", theme_type_variation + "_hbox") # _container.theme_type_variation)
	
	_tween = create_tween()
	_tween.kill()
	
	if show_dots:		
		var dots_clipper = MarginContainer.new()					
		dots_clipper.clip_contents = true
		dots_clipper.add_theme_constant_override("margin_left", 40)
		dots_clipper.add_theme_constant_override("margin_right", 40)
		dots_clipper.add_theme_constant_override("margin_bottom", 20)		
		#dots_clipper.size = Vector2(size.x, 40)
		dots_hbox = preload("res://addons/ExtraUIControls/carousel.tscn").instantiate()
		dots_hbox.loop = false
		dots_hbox.align_center = true
		dots_hbox.show_dots = false		
		dots_hbox.init_on_ready = false		
		dots_clipper.add_child(dots_hbox)
		_nav_controls.push_back(dots_clipper)
		#dots_hbox.alignment = FlowContainer.ALIGNMENT_CENTER
		add_child(dots_clipper)
		dots_hbox.set_meta("button_group", ButtonGroup.new())		
		dots_hbox.item_selected.connect(jump_to)
	if init_on_ready:
		init_items()	
		
	if enable_buttons:
		_add_nav_buttons()

func clear_items():
	for child in _container.get_children():
		_container.remove_child(child)
		child.queue_free()
	_items.clear()
	_clones.clear()

func init_items():
	_items.clear()
	for clone in _clones:
		_container.remove_child(clone)
		clone.queue_free()
	for item in _container.get_children():
		_items.append(item)
		item.size_flags_vertical = SIZE_EXPAND_FILL if expand_children_vertically else SIZE_SHRINK_CENTER
		_container.remove_child(item)		
	for child in get_children():
		if child in _nav_controls: continue
		if child is Control:
			_items.append(child)
			child.size_flags_vertical = SIZE_EXPAND_FILL if expand_children_vertically else SIZE_SHRINK_CENTER
			remove_child(child)
			if child.mouse_filter == Control.MOUSE_FILTER_STOP:
				child.mouse_filter = Control.MOUSE_FILTER_PASS 
	
	if loop and _items.size() >= visible_count + 2:
		# Clone last 'visible_count' items at front and first 'visible_count' items at end for seamless looping
		for i in range(_items.size() - visible_count, _items.size()):
			var clone = _items[i].duplicate()
			_clones.push_back(clone)
			_container.add_child(clone)
		for item in _items:
			_container.add_child(item)
		for i in range(visible_count):
			var clone = _items[i].duplicate()
			_clones.push_back(clone)
			_container.add_child(clone)
		_current_index = visible_count
	else:
		loop = false
		visible_count = _items.size()
		for item in _items:
			_container.add_child(item)
		_current_index = 0

	for i in _container.get_child_count():
		var item: Control = _container.get_child(i)
		for connection in item.gui_input.get_connections():
			item.gui_input.disconnect(connection.callable)
		item.gui_input.connect(func(event: InputEvent):
			if event is InputEventScreenTouch and not event.pressed:
				if not _is_dragging:
					item_tapped.emit(_real_index(i), item)
		)
		
	if show_dots:		
		_dot_buttons.clear()		
		for child in dots_hbox._container.get_children():
			dots_hbox.remove_child(child)
			child.queue_free()
		var button_group = dots_hbox.get_meta("button_group")
		for i in len(_items):
			var button = Button.new()
			_dot_buttons.push_back(button)
			dots_hbox.add_child(button)
			button.text = str(i + 1) if dots_numbered else ""
			button.focus_mode = Control.FOCUS_NONE
			button.toggle_mode = true
			button.button_group = button_group
			if i == _current_index:
				button.button_pressed = true
			button.toggled.connect(func(on): if on: jump_to(i))
			#button.pressed.connect(func(): jump_to(i))
			button.theme_type_variation = theme_type_variation + "_dots_buttons"				
		dots_hbox.init_items()
		await get_tree().process_frame			
		var margin  = dots_hbox.get_parent()
		margin.size.x = margin.get_parent().size.x
		margin.position.y = margin.get_parent().size.y - 80
		margin.size.y = 60
		#dots_hbox.size.x = 0 #dots_hbox.get_parent().size.x-80
		#dots_hbox.get_parent().position = Vector2(0, dots_hbox.get_parent().size.y-40)
		
	if not is_visible_in_tree():	
		if not visibility_changed.is_connected(_set_initial_positions.call_deferred):
			visibility_changed.connect(_set_initial_positions.call_deferred)		
	else:
		_set_initial_positions.call_deferred()
				
func _real_index(visible_index: int) -> int:
	if loop and _items.size() >= visible_count + 2:
		var total = _container.get_child_count()
		if visible_index < visible_count:
			return visible_index - visible_count + _items.size()
		elif visible_index >= total - visible_count:
			return visible_index - (total - visible_count)
		else:
			return visible_index - visible_count
	else:
		return visible_index

func _set_initial_positions():	
	await get_tree().process_frame						
	if not _container:
		return
	var positions: Array[float] = []
	var x_offset := 0.0
	for i in _container.get_child_count():
		positions.append(x_offset)
		var item: Control = _container.get_child(i)
		x_offset += item.size.x + spacing
	_positions = positions
	if _container.get_child_count() > 0: 
		_update_positions.call_deferred()
	if visibility_changed.is_connected(_set_initial_positions):
		visibility_changed.disconnect(_set_initial_positions)

func _update_positions(immediate: bool = false) -> void:
	if not _positions: return
	var max_index: int = _container.get_child_count() - 1
	var target_x: float = 0.0
	if _current_index >= 0 and _current_index <= max_index:
		target_x = - _positions[_current_index]
	if align_center:
		target_x += (size.x - _container.get_child(_current_index).size.x) / 2
	if immediate:
		if _tween.is_running(): await _tween.finished
		_container.position.x = target_x
		#_container.position = Vector2(0,0)
	else:
		_tween.kill()
		_tween = create_tween()
		_tween.tween_property(_container, "position:x", target_x, animation_speed).set_trans(Tween.TransitionType.TRANS_QUAD).set_ease(Tween.EaseType.EASE_OUT)	

func next() -> void:
	if disabled:
		return
	if loop:
		_current_index += 1
		_update_positions()
		_check_loop_bounds_delayed()
	else:
		if _current_index < _container.get_child_count() - 1: # - visible_count:
			_current_index += 1
			_update_positions()

func prev() -> void:
	if disabled:
		return
	if loop:
		_current_index -= 1
		_update_positions()
		_check_loop_bounds_delayed()
	else:
		if _current_index > 0:
			_current_index -= 1
			_update_positions()

func jump_to(index: int) -> void:
	if disabled:
		return
	if loop:		
		_current_index = index + visible_count
		_update_positions()
		_check_loop_bounds_delayed()
	else:
		_current_index = clamp(index, 0, _container.get_child_count() - 1) # - visible_count)
		_update_positions()

func _check_loop_bounds_delayed() -> void:
	var max_index: int = _container.get_child_count() - visible_count - 1 if loop else _container.get_child_count() - 1
	var min_index: int = visible_count if loop else 0
	await get_tree().create_timer(animation_speed).timeout
	if _current_index > max_index:
		_current_index = min_index
		_update_positions(true)
	elif _current_index < min_index - 1:
		_current_index = max_index - 1
		_update_positions(true)

func _gui_input(event: InputEvent) -> void:	
	if not enable_touch:
		return
	if disabled:
		return

	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode in [KEY_LEFT, KEY_A]:
			prev()
		elif event.keycode in [KEY_RIGHT, KEY_D]:
			next()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_active = true
			_is_dragging = false
			_touch_start_pos = event.position + global_position
			_tween.kill()
			_touch_active = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.warp_mouse(_touch_start_pos)
			_touch_active = false
			if _is_dragging:
				#var positions: Array[float] = _get_cumulative_widths()
				if _tween.is_running():
					pass
				var _idx = 0
				var closest_distance = 100000000
				var target_position = global_position + size/2
				
				for item in _container.get_children():
					var distance = (item.global_position + item.size/2 ).distance_to(target_position)					
					if distance < closest_distance:
						closest_distance = distance
						_idx = item.get_index()					
				_current_index = _idx
				_update_positions()
				_check_loop_bounds_delayed()
				_is_dragging = false

	if event is InputEventScreenDrag and _touch_active:
		var delta_x: float = event.relative.x
		if abs(delta_x) > 2:
			_is_dragging = true
			if _tween.is_running(): _tween.kill()
			var new_x = _container.position.x + delta_x
			if loop:
				if new_x > 0 and event.relative.x > 0: new_x -= _positions[len(_items)]
				if -new_x > _positions[len(_items)] and event.relative.x < 0: new_x += _positions[len(_items)]
			else:
				new_x = clamp(new_x, 0.5 * size.x -20 -_container.size.x, 0.5 * size.x+ 20)
			_container.position.x = new_x
						
func _process(_delta):
	if len(nav_buttons_queue) > 0 and not _tween.is_running():
		if nav_buttons_queue.pop_front() == -1:
			prev()
		else:
			next()
						
func _add_nav_buttons() -> void:
	var prev_button := Button.new()
	prev_button.text = "<"
	prev_button.pressed.connect(func():
		nav_buttons_queue.push_back(-1)
		prev_button.release_focus()
	)
	add_child(prev_button)
	prev_button.name = "prev"
	prev_button.set_anchors_and_offsets_preset(PRESET_CENTER_LEFT)
	prev_button.theme_type_variation = theme_type_variation + "_nav_buttons"
	
	var next_button := Button.new()
	next_button.text = ">"
	next_button.pressed.connect(func():
		nav_buttons_queue.push_back(1)
		next_button.release_focus()
	)
	add_child(next_button)
	next_button.name = "next"
	next_button.set_anchors_and_offsets_preset(PRESET_CENTER_RIGHT)
	next_button.theme_type_variation = theme_type_variation + "_nav_buttons"
	
	_nav_controls.push_back(prev_button)
	_nav_controls.push_back(next_button)
