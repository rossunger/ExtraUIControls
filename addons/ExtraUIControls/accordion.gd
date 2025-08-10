@tool
extends VBoxContainer

@export var transition_duration = 0.25
@export var horizontal_expand = true
@export var current_item: Control
var button_group = ButtonGroup.new()
var items = []

func _ready():
	if Engine.is_editor_hint() and EditorInterface.get_edited_scene_root().is_ancestor_of(self):
		return
	button_group.allow_unpress = true
	var min_x = get_rect().size.x
	for child: Control in get_children():
		items.push_back(child)
		child.visible = true
		var button = Button.new()
		button.custom_minimum_size.x = min_x
		button.text = child.name
		button.toggle_mode = true
		button.button_group = button_group
		if child == current_item:
			button.set_pressed_no_signal(true)
		button.toggled.connect(func(on):
			if on:
				current_item = child
				toggle_child.call_deferred(child, true)
			else:
				toggle_child.call_deferred(child, false)
				if current_item == child:
					current_item = null
			button.release_focus()
		)
		add_child(button)
		move_child(button, child.get_index())
		var clip_node = ColorRect.new()
		clip_node.name = "ClippingNode"
		clip_node.size = child.size
		clip_node.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		
		button.add_sibling(clip_node)
		button.theme_type_variation = theme_type_variation + "_button"
		child.reparent(clip_node)
		if horizontal_expand:
			child.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	if current_item and is_ancestor_of(current_item):
		toggle_child.call_deferred(current_item, true)
		
func toggle_child(who = current_item, show = true):
	if not who: return
	var clip_node = who.get_parent()
	var tween: Tween = clip_node.create_tween()
	tween.tween_property(clip_node, "custom_minimum_size:y", 0 if not show else who.size.y, transition_duration)
	if not show:
		tween.finished.connect(who.hide)
	else:
		who.visible = true

func close_all():
	var button = button_group.get_pressed_button()
	if button:
		button.button_pressed = false

func recalculate():
	for item in items:
		item.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		toggle_child.call_deferred(item, item == current_item)
