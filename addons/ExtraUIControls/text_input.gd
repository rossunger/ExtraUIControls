extends LineEdit

signal text_change_requested

enum INPUT_MODES{
	NONE, INT, FLOAT, NUMBER, DATE, TIME, DATE_TIME
}

@export var filter: INPUT_MODES
var old_text

func _ready():
	old_text = text
	text_submitted.connect(func(txt):
		if pre_validate():			
			text_change_requested.emit(old_text, txt)
			old_text = text
		else:
			text = old_text			
	)
	focus_exited.connect(func():
		if pre_validate():
			text_change_requested.emit(old_text, text)
			old_text = text
		else:
			text = old_text
	)

func pre_validate():
	if filter == INPUT_MODES.INT:
		return text.is_valid_int()
	if filter == INPUT_MODES.FLOAT:
		return text.is_valid_float()
	if filter == INPUT_MODES.NUMBER:
		return text.is_valid_float() or text.is_valid_int()
	if filter == INPUT_MODES.DATE:
		pass
	return true
	
func reset_text():
	text = old_text
