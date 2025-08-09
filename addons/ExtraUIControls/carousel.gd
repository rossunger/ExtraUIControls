extends Control

signal item_tapped(index: int)

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


var _items: Array[Control] = []
var _container: HBoxContainer
var _tween: Tween

var _current_index: int = 0
var _touch_active: bool = false
var _positions: Array[float]

# Drag variables
var _is_dragging: bool = false
var _touch_start_pos: Vector2

var _dot_buttons = []

func _ready() -> void:
	item_tapped.connect(func(id, node): print(id, ":", node))	
	_items.clear()
	for child in get_children():
		if child is Control:
			_items.append(child)
			child.size_flags_vertical = SIZE_EXPAND_FILL if expand_children_vertically else SIZE_SHRINK_CENTER 
			remove_child(child)

	_container = HBoxContainer.new()
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

	if loop and _items.size() >= visible_count + 2:
		# Clone last 'visible_count' items at front and first 'visible_count' items at end for seamless looping
		for i in range(_items.size() - visible_count, _items.size()):
			var clone = _items[i].duplicate()
			_container.add_child(clone)
		for item in _items:
			_container.add_child(item)
		for i in range(visible_count):
			var clone = _items[i].duplicate()
			_container.add_child(clone)
		_current_index = visible_count
	else:
		for item in _items:
			_container.add_child(item)
		_current_index = 0

	for i in _container.get_child_count():
		var item: Control = _container.get_child(i)
		item.gui_input.connect(func(event: InputEvent):
			if event is InputEventScreenTouch and not event.pressed:								
				if not _is_dragging: 
					item_tapped.emit(_real_index(i), item)				
		)

	_tween = create_tween()	
	_tween.kill()

	if enable_buttons:
		_add_nav_buttons()
	if show_dots:
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(hbox)							
		var button_group = ButtonGroup.new()
		for i in len(_items):
			var button = Button.new()
			_dot_buttons.push_back(button)
			hbox.add_child(button)
			button.text = str(i+1) if dots_numbered else ""			
			button.toggle_mode = true
			button.button_group = button_group
			if i == _current_index:
				button.button_pressed = true			
			button.toggled.connect(func(on): if on: jump_to(i))
			button.theme_type_variation = theme_type_variation + "_dots_buttons" 
		hbox.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)		
	_positions = _get_cumulative_widths()
	_update_positions(true)
	
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

func _get_cumulative_widths() -> Array[float]:
	var positions: Array[float] = []
	var x_offset := 0.0
	for i in _container.get_child_count():
		positions.append(x_offset)
		var item: Control = _container.get_child(i)
		x_offset += item.size.x + spacing
	return positions

func _update_positions(immediate: bool = false) -> void:	
	var max_index: int = _container.get_child_count() - 1	
	var target_x: float = 0.0
	if _current_index >= 0 and _current_index <= max_index:		
		target_x = -_positions[_current_index] #+ _drag_offset_x
	if align_center:
		target_x += (size.x - _container.get_child(_current_index).size.x)/2
	if immediate:
		if _tween.is_running(): await _tween.finished
		_container.position.x = target_x
		#_container.position = Vector2(0,0)
	else:
		_tween.kill()
		_tween = create_tween()
		_tween.tween_property(_container, "position:x", target_x, animation_speed).set_trans(Tween.TransitionType.TRANS_QUAD).set_ease(Tween.EaseType.EASE_OUT)
	#for i in len(_dot_buttons):		
		#_dot_buttons[i].set_pressed_no_signal(i== _current_index)	
func next() -> void:
	if loop:
		_current_index += 1		
		_update_positions()
		_check_loop_bounds_delayed()
	else:
		if _current_index < _container.get_child_count() -1:# - visible_count:
			_current_index += 1
			_update_positions()

func prev() -> void:
	if loop:
		_current_index -= 1
		_update_positions()
		_check_loop_bounds_delayed()
	else:
		if _current_index > 0:
			_current_index -= 1
			_update_positions()

func jump_to(index: int) -> void:
	if loop:
		_current_index = index + visible_count		
		_update_positions()
		_check_loop_bounds_delayed()
	else:
		_current_index = clamp(index, 0, _container.get_child_count() -1)#- visible_count)
		_update_positions()

func _check_loop_bounds_delayed() -> void:
	var max_index: int = _container.get_child_count() - visible_count - 1
	var min_index: int = visible_count 
	await get_tree().create_timer(animation_speed).timeout
	if _current_index > max_index:
		_current_index = min_index		
		_update_positions(true)
	elif _current_index < min_index-1:
		_current_index = max_index - 1
		_update_positions(true)	

func _gui_input(event: InputEvent) -> void:
	if not enable_touch:
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
				var pos_x: float = fmod(_container.position.x, _positions[-1])
				var closest_idx: int = 0
				var closest_dist: float = 1e10				
				for i in _positions.size():
					var dist: float = abs(-_positions[i] - pos_x + size.x/2 - _container.get_child(i).size.x/2)
					if dist < closest_dist:
						closest_dist = dist
						closest_idx = i				
				_current_index = closest_idx								
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
			_container.position.x = new_x			
						
func _add_nav_buttons() -> void:
	var prev_button := Button.new()
	prev_button.text = "<"	
	prev_button.pressed.connect(prev)
	add_child(prev_button)
	prev_button.name = "prev"
	prev_button.set_anchors_and_offsets_preset(PRESET_CENTER_LEFT)
	prev_button.theme_type_variation = theme_type_variation + "_nav_buttons" 
	
	var next_button := Button.new()
	next_button.text = ">"	
	next_button.pressed.connect(next)
	add_child(next_button)
	next_button.name = "next"
	next_button.set_anchors_and_offsets_preset(PRESET_CENTER_RIGHT)
	next_button.theme_type_variation = theme_type_variation + "_nav_buttons" 
