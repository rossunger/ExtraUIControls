@tool 
extends PanelContainer

enum CONTAINER_TYPES{
	VBOX, HBOX, VFLOW, HFLOW, SCROLL, TAB
}
@export var container_type: CONTAINER_TYPES
@export var margin:int = 12
@export var separation:int = 4
@export_tool_button("(re)create") var do_update = update
var margin_container
var container

func _enter_tree():	
	if Engine.is_editor_hint() and is_node_ready():
		update()
		
func _ready():
	if not Engine.is_editor_hint():
		update()
	else:
		if get_child_count() == 1:
			margin_container = get_child(0) 
		else:
			update()

func update(): 
	if get_child_count() == 1:
		margin_container = get_child(0)  
	else:
		margin_container = MarginContainer.new()	
		add_child(margin_container)
		margin_container.owner = owner
		margin_container.name = "MarginContainer"
	if margin_container.get_child_count() > 1:
		push_error("margin container has too many children!")
	else: 					
		var container
		if container_type == CONTAINER_TYPES.VBOX: container = VBoxContainer.new()
		if container_type == CONTAINER_TYPES.HBOX: container = HBoxContainer.new()
		if container_type == CONTAINER_TYPES.VFLOW: container = VFlowContainer.new()
		if container_type == CONTAINER_TYPES.HFLOW: container = HFlowContainer.new()
		if container_type == CONTAINER_TYPES.SCROLL: container = ScrollContainer.new()
		if container_type == CONTAINER_TYPES.TAB: container = TabContainer.new()		
		if margin_container.get_child_count() == 1:	
			var child = margin_container.get_child(0)
			child.replace_by(container) 
			child.queue_free()
		else:
			margin_container.add_child(container)
		container.owner = owner
		container.name = "Container"		
		margin_container.add_theme_constant_override("margin_left", margin)
		margin_container.add_theme_constant_override("margin_top", margin)
		margin_container.add_theme_constant_override("margin_right", margin)
		margin_container.add_theme_constant_override("margin_bottom", margin)
		container.add_theme_constant_override("separation",separation)	
