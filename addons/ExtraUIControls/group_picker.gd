extends Control

signal group_add_requested(new_name)
signal group_rename_requested(old_name, new_name)
signal group_remove_requested(group_name)
signal group_tags_changed
signal group_selection_changed(selected_groups:Array)

signal tag_rename_requested(old_name, new_name)
signal tag_state_changed(selected_tags:Array, match_all:bool, invert_selection:bool)
signal tag_add_requested(new_name)
signal tag_remove_requested(tag_name)

@export var groups = {"color":["red"], "size":["big", "small"]}
@export var toggle_mode_only = false
var multi_select_echo = false

var icon_close = preload("icons/icon_close.svg")

func _ready():
	%groups_search.text_changed.connect(filter_groups)	
	%add_group_button.pressed.connect(group_add_requested.emit)	
	var tag_list = []
	for group in groups:
		for tag in groups[group]:
			if not tag_list.has(tag):
				tag_list.push_back(tag)
	%tag_picker.tag_list = tag_list
	%tag_picker.groups = groups	
	%tag_picker.build_tag_tree()
	%tag_picker.tag_state_changed.connect(update_group_tags)		
	if toggle_mode_only:
		%groups_tree.item_edited.connect(group_toggled)
	else:
		%groups_tree.multi_selected.connect(groups_selected)
		%groups_tree.item_activated.connect(func(): %groups_tree.edit_selected(true))
		%groups_tree.item_edited.connect(func():
			var item = %groups_tree.get_edited()		
			group_rename_requested.emit(item.get_metdata(0), item.get_text(0))
		)	
		%groups_tree.nothing_selected.connect(set_group_tags)
		%groups_tree.button_clicked.connect(func(item,column,id,mouse_button_id): group_remove_requested.emit(item.get_text(0)))
	%groups_tree.nothing_selected.connect(%groups_tree.deselect_all)			
	build_groups_tree()
	
	%tag_picker.tag_rename_requested.connect(tag_rename_requested.emit)
	%tag_picker.tag_add_requested.connect(tag_add_requested.emit)
	%tag_picker.tag_remove_requested.connect(tag_remove_requested.emit)		
	
func build_groups_tree():
	%groups_tree.clear()	
	var root:TreeItem = %groups_tree.create_item()
	for group in groups.keys():
		var item = root.create_child()
		item.set_text(0, group)	
		if not toggle_mode_only:
			item.add_button(0, icon_close)	
	
func filter_groups(text):
	for child in %groups_tree.get_root().get_children():
		child.visible = child.get_text(0).containsn(text) or text.is_empty()
		
func update_group_tags(tag_list):
	var next_item = %groups_tree.get_next_selected(null)
	var items = []
	while next_item:		
		items.push_back(next_item)
		next_item = %groups_tree.get_next_selected(next_item)		
	for item in items:
		groups[item.get_text] = items.map(func(a):return a.get_text(0))
	pass

func set_group_tags():		
	var group = %groups_tree.get_selected()
	if group:
		var g= groups[group.get_text(0)]
		%tag_picker.active_tags = groups[group.get_text(0)]
		%tag_picker.build_tag_tree()
	else:
		%tag_picker.active_tags = []
		%tag_picker.build_tag_tree()

func groups_selected(item, column, selected):
	multi_select_echo = true
	set_group_tags()
	set.call_deferred("multi_select_echo", false)

func group_toggled():
	var selected_groups = []
	for group:TreeItem in %groups_tree.get_root().get_children():
		if group.is_checked(0):
			selected_groups.push_back(group.get_text(0))
	group_selection_changed.emit(selected_groups)
