extends Control

signal tag_rename_requested(old_name, new_name)
signal tag_state_changed(selected_tags:Array, match_all:bool, invert_selection:bool)
signal tag_add_requested(new_name)
signal tag_remove_requested(tag_name)

@export var groups = {"color":["red"]}
@export var tag_list = ["hidden", "red"]
@export var active_tags = ["hidden"]
@export var show_filter_buttons = true
@export var toggle_mode_only = false

var icon_close = preload("icons/icon_close.svg")

func _ready():
	#build_tag_tree()
	%tag_search.text_changed.connect(filter_tags)
	%grouping_button.toggled.connect(func(a):build_tag_tree() )		
	if toggle_mode_only:
		%add_tag_button.visible = false #queue_free()
		%match_all_or_any_button.visible = false  #.queue_free()				
		%not_button.visible = false #.queue_free()				
	else:
		%add_tag_button.pressed.connect(tag_add_requested.emit)
		%match_all_or_any_button.toggled.connect(toggle_match_all)
		%not_button.toggled.connect(toggle_not)
	%tags_tree.item_edited.connect(item_edited)

func item_edited():
	var item = %tags_tree.get_edited()
	var col = %tags_tree.get_edited_column()
	if col == 0:
		var tag_name = item.get_text(0) if toggle_mode_only else item.get_text(1)
		if item.is_checked(0):
			if not active_tags.has(tag_name):
				active_tags.push_back(tag_name)
		else:
			if active_tags.has(tag_name):
				active_tags.erase(tag_name)
		tag_state_changed.emit(active_tags, %match_all_or_any_button.button_pressed, %not_button.button_pressed)
	elif col == 1:
		tag_rename_requested.emit(item.get_metadata(1), item.get_text(1))
	
func build_tag_tree():
	%tags_tree.clear()
	var root:TreeItem = %tags_tree.create_item()	
	if toggle_mode_only:
		%tags_tree.set_column_expand(0, true)
		%tags_tree.columns = 1
	else:
		%tags_tree.columns = 2
		%tags_tree.set_column_expand(0, false)
		%tags_tree.item_activated.connect(%tags_tree.edit_selected.bind(true))
		
	if %grouping_button.button_pressed:
		var tags_left = tag_list.duplicate()
		for group in groups.keys():
			var group_item = root.create_child()
			group_item.set_text(0, group)
			for tag in groups[group]:
				build_tag_item(group_item, tag)
				tags_left.erase(tag)
		var group_item = root.create_child()
		group_item.set_text(0, "other")
		for tag in tags_left:
			build_tag_item(group_item, tag)				
	else:		
		for tag in tag_list:
			build_tag_item(root, tag)		

func build_tag_item(root, tag):
	var tag_item = root.create_child()
	tag_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)	
	tag_item.set_editable(0, true)		
	tag_item.set_checked(0, tag in active_tags)
	if not toggle_mode_only:
		tag_item.set_text(1, tag)
		#tag_item.set_editable(1, true)
		tag_item.set_metadata(1, tag)
		tag_item.add_button(1,icon_close)
	else:
		tag_item.set_text(0, tag)		

func filter_tags(text):
	for item in %tags_tree.get_root().get_children():
		if %grouping_button.button_pressed:
			for tag_item in item.get_children():
				var item_text = tag_item.get_text(0) if toggle_mode_only else tag_item.get_text(1)
				tag_item.visible = item_text.containsn(text) or text.is_empty()
		else:			
			var item_text = item.get_text(0) if toggle_mode_only else item.get_text(1)
			item.visible = item_text.containsn(text) or text.is_empty()

#func add_tag():
	#var new_tag = "new_tag"
	#var i = 1
	#while tag_list.has(new_tag):
		#new_tag = "new_tag_" + i 
		#i += 1
	#tag_list.push_back(new_tag)
	
func toggle_match_all(on):
	%match_all_or_any_button.text = "Match All" if on else "Match Any" 		
	tag_state_changed.emit(active_tags, %match_all_or_any_button.button_pressed, %not_button.button_pressed)
	
func toggle_not(on):
	%not_button.text = "selected" if on else "not selected"
	tag_state_changed.emit(active_tags, %match_all_or_any_button.button_pressed, %not_button.button_pressed)
