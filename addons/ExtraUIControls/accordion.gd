extends VBoxContainer

@export var transition_duration = 0.25
@export var starting_item:Control
var items = []

func _ready():
	var button_group = ButtonGroup.new()
	button_group.allow_unpress = true
	var min_x = get_rect().size.x
	for child in get_children():
		items.push_back(child)
		child.visible = false
		var button = Button.new()		
		button.custom_minimum_size.x = min_x
		button.text = child.name
		button.toggle_mode = true
		button.button_group = button_group		
		button.toggled.connect(func(on):
			if on: 
				toggle_children(child, true)
			else:
				toggle_children(child, false)
			button.release_focus()				
		)
		add_child(button)
		move_child(button, child.get_index())
		var clip_node = ColorRect.new()
		clip_node.size = child.size
		clip_node.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		button.add_sibling(clip_node)
		button.theme_type_variation = theme_type_variation + "_button"
		child.reparent(clip_node)
	if starting_item and is_ancestor_of(starting_item):
		toggle_children(starting_item, true)
		
func toggle_children(who, show):		
	var clip_node = who.get_parent()
	var tween: Tween = clip_node.create_tween()
	tween.tween_property(clip_node, "custom_minimum_size:y", 0 if not show else who.size.y, transition_duration )
	if not show:
		tween.finished.connect(who.hide)
	else:
		who.visible = true
		#item.visible = item == who
			
