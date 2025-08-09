extends Control

signal input_correct
signal input_incorrect

@export var answer = "": 
	set(val):		
		if not answer == val:
			answer = val		
			set_answer(val)

@export var numbers_only = true

func set_answer(val:String):	
	while len(answer) > get_child_count():
		var node := LineEdit.new()
		node.alignment = HORIZONTAL_ALIGNMENT_CENTER
		node.theme_type_variation = theme_type_variation + "_line_edit"
		node.text_changed.connect(text_changed.bind(node))
		node.focus_entered.connect(func(): node.text = "")
		node.gui_input.connect(func (event: InputEvent):		
			if event is InputEventKey and event.keycode == KEY_BACKSPACE and event.pressed:
				get_child(node.get_index()-1).grab_focus()
				node.release_focus()
			elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
				node.release_focus()
		)
		add_child(node)
	while len(answer) < get_child_count():
		var child = get_child(-1)
		remove_child(child)
		child.queue_free()

func text_changed(text, node:Node):
	if text.is_empty(): return
	if numbers_only and not text.is_valid_int():
		node.text = ""
		return
	var id = node.get_index() +1
	var max = get_child_count()
	var next_node: Control = get_child(id) if get_child_count() > node.get_index() +1 else null
	if next_node:
		next_node.grab_focus()
	else:
		if check_answer():
			input_correct.emit()
		else:
			input_incorrect.emit()
		node.release_focus()
	
func check_answer()->bool:
	var input = ""
	for child in get_children():
		input += child.text
	return input == answer	
