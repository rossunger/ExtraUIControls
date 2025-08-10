@tool
extends Control

var button_group := ButtonGroup.new()

func _ready():
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root().is_ancestor_of(self):
		return
	for child in get_children():
		if child is Button:
			child.toggle_mode = true
			child.button_group = button_group
