@tool
extends Control

signal value_changed

enum DIRECTIONS {
	VERTICAL, HORIZONTAL
}
#@export var direction: DIRECTIONS
@export var options: String = "1\n2\n3\n4\n5\n6\n7":
	set(val):
		options = val
		updating_settings = true
		
@export var font_size: int = 32:
	set(val):
		font_size = val
		updating_settings = true
		
@export var looping = true
@export var show_buttons = true:
	set(val):
		show_buttons = val
		updating_settings = true
			
@export var margins: int = 12:
	set(val):
		margins = val
		updating_settings = true
@onready var label: Label = %SpinBoxLabel
@export var clip_options := false:
	set(val):
		clip_options = val
		updating_settings = true

@export_tool_button("update") var update_button = update_settings

var value = 0:
	set(val):
		value = val
		updating_settings = true

var dragging = false
var original_mouse_position: Vector2

var updating_settings = true

func update_settings():
	%SpinBoxButtons.visible = show_buttons
	clip_contents = clip_options
	var label_parent = label.get_parent()
	label_parent.clip_contents = clip_options
	label.text = options
	label.label_settings.font_size = font_size
	update_sizes()
	var parent_size_y = label_parent.size.y
	label.position.y = - value * label.get_line_height() # + margins - parent_size_y/2 + (parent_size_y - font_size)
	
func _physics_process(delta):	
	if updating_settings:
		update_settings()
		updating_settings = false
	
func get_value_text() -> String:
	return label.text.split("\n")[value]

func update_sizes():
	var label_parent = label.get_parent()
	custom_minimum_size.y = label.get_line_height() + margins * 2
	size.y = custom_minimum_size.y
	label_parent.custom_minimum_size.y = label.get_line_height()
	
	var min_x = get_min_x()
	label.custom_minimum_size.x = min_x
	label_parent.size.x = max(min_x, label_parent.size.x)
	label.size.x = min_x # max(min_x, label_parent.size.x - margins*2)
	label.position.x = (label_parent.size.x - label.size.x) / 2
	if show_buttons:
		custom_minimum_size.x = max(min_x, label.size.x + %SpinBoxButtons.size.x + margins * 2)
	else:
		custom_minimum_size.x = max(custom_minimum_size.x, label.size.x + margins * 2)

func _ready():
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root().get_parent().is_ancestor_of(self):
		return
	label.get_parent().resized.connect(update_sizes)
	%SpinBoxButtons.up.connect(next)
	%SpinBoxButtons.down.connect(previous)
	update_settings()
	label.theme_type_variation = owner.theme_type_variation + "_" + "spinbox_label"
	update_sizes()
	
func get_min_x() -> int:
	var rows = options.split("\n")
	var longest_row = ""
	for row in rows:
		longest_row = row if len(row) > len(longest_row) else longest_row
	var font: Font = label.get_theme_font("font")
	return font.get_string_size(longest_row, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x

func next():
	value = value + 1 if value < label.get_line_count() - 1 else 0

func previous():
	value = value - 1 if value > 0 else label.get_line_count() - 1
		
func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root().get_parent().is_ancestor_of(self):
		return
	if event is InputEventScreenTouch:
		if dragging and event.pressed == false:
			value = - round(label.position.y / label.get_line_height())
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.warp_mouse(original_mouse_position + global_position)
			dragging = false
	elif event is InputEventScreenDrag:
		if not dragging:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			dragging = true
			original_mouse_position = event.position
		if true: # direction == DIRECTIONS.VERTICAL:
			label.position.y = clamp(label.position.y + event.screen_relative.y, (-label.get_line_count() + 1) * label.get_line_height(), 0)
			if looping:
				if label.position.y == 0 and event.screen_relative.y > 0:
					label.position.y = (-label.get_line_count() + 1) * label.get_line_height()
				elif label.position.y == (-label.get_line_count() + 1) * label.get_line_height() and event.screen_relative.y < 0:
					label.position.y = 0
		else:
			label.position.x = clamp(label.position.x + event.screen_relative.x, (-label.get_line_count() + 1) * label.get_line_height(), 0)
			if looping:
				var max_x = 100
				if label.position.x == 0 and event.screen_relative.x < 0:
					label.position.x = max_x
				elif label.position.x == max_x and event.screen_relative.y > 0:
					label.position.x = 0
