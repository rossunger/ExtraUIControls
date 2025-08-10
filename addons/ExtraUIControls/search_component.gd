@tool
extends Control

signal text_changed

@onready var search_box: LineEdit = %search_box
@onready var search_hbox: Control = %search_hbox
@onready var search_button: Button = %search_button
@onready var clear_button: Button = %clear_button
@export var align_right: bool
@export var always_show_input: bool = true

func _ready():
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root().get_parent().is_ancestor_of(self):
		return
	if align_right:
		move_child(search_button, -1)
	search_hbox.visible = always_show_input
	clear_button.visible = false
	if always_show_input:
		search_button.disabled = true
	else:
		search_button.pressed.connect(func():
			search_hbox.visible = true
			#search_button.visible = false
			search_box.grab_focus()
		)
	clear_button.pressed.connect(func():
		if search_box.text == "":
			search_focus_ended()
			return
		search_box.text = ""
		clear_button.visible = false
		search_box.grab_focus()
		search_box.focus_exited.connect(search_focus_ended)
		text_changed.emit(search_box.text)
	)
	search_box.text_changed.connect(func(new_text):
		text_changed.emit(new_text)
		if new_text == "":
			clear_button.visible = false
			if not search_box.focus_exited.is_connected(search_focus_ended):
				search_box.focus_exited.connect(search_focus_ended)
		else:
			clear_button.visible = true
			if search_box.focus_exited.is_connected(search_focus_ended):
				search_box.focus_exited.disconnect(search_focus_ended)
	)

func search_focus_ended():
	search_hbox.visible = always_show_input
	search_button.visible = true
	if search_box.focus_exited.is_connected(search_focus_ended):
		search_box.focus_exited.disconnect(search_focus_ended)

func _input(event):
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root().get_parent().is_ancestor_of(self):
		return
	if event is InputEventScreenTouch and event.pressed:
		if not get_global_rect().has_point(event.position):
			search_box.release_focus()
