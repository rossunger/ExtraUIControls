extends PanelContainer

signal filter_changed(selected_groups:Array, selected_tags:Array, match_all_tags:bool, invert_tag_selection:bool, sort_mode:String)
signal tag_rename_requested(old_name, new_name)
#signal tag_state_changed(selected_tags:Array, match_all:bool, invert_selection:bool)
signal tag_add_requested(new_name)
signal tag_remove_requested(tag_name)
signal group_add_requested(new_name)
signal group_rename_requested(old_name, new_name)
signal group_remove_requested(group_name)
signal group_tags_changed(groups)
#signal group_selection_changed(selected_groups:Array)

@export var tags = []
@export var groups = {} # group_name: [tag_name, tag_name2]
@export var sort = []
@export var search = true

var selected_groups = []
var selected_tags = []
var selected_match_all = false
var selected_invert_tag_selection = false
var selected_sort_mode

var button_group = ButtonGroup.new()

var debug = true

func _ready():
	if debug:
		groups = %groups_tab.groups
		tags = %tags_tab.tag_list
		sort = %sort_tab.options
	else:
		%groups_tab.groups = groups
		%tags_tab.tag_list = tags
		%sort_tab.options = sort
				
	%tag_button.visible = not tags.is_empty()
	%grouping_button.visible = not groups.is_empty()
	%sort_button.visible = not sort.is_empty()
	%search.visible = search
	
	%tag_button.toggled.connect(toggle_tab.bind(%tags_tab))
	%grouping_button.toggled.connect(toggle_tab.bind(%groups_tab))
	%sort_button.toggled.connect(toggle_tab.bind(%sort_tab))
	
	%tags_tab.visible = false
	%groups_tab.visible = false
	%sort_tab.visible = false
	
	%tag_button.button_group = button_group
	%grouping_button.button_group = button_group
	%sort_button.button_group = button_group
	button_group.allow_unpress = true	

	%tags_tab.tag_rename_requested.connect(tag_rename_requested.emit)
	%tags_tab.tag_add_requested.connect(tag_add_requested.emit)
	%tags_tab.tag_remove_requested.connect(tag_remove_requested.emit)		
	%groups_tab.group_add_requested.connect(tag_rename_requested.emit)
	%groups_tab.group_rename_requested.connect(group_rename_requested.emit)
	%groups_tab.group_remove_requested.connect(group_remove_requested.emit)
	%groups_tab.group_tags_changed.connect(group_tags_changed.emit)
	%groups_tab.tag_rename_requested.connect(tag_rename_requested.emit)
	%groups_tab.tag_add_requested.connect(tag_add_requested.emit)
	%groups_tab.tag_remove_requested.connect(tag_remove_requested.emit)		
	
	%tags_tab.tag_state_changed.connect(func (_selected_tags:Array, _match_all:bool, _invert_selection:bool):				
		selected_tags = _selected_tags
		selected_match_all = _match_all
		selected_invert_tag_selection = _invert_selection
		filter_changed.emit(selected_groups, selected_tags, selected_match_all,selected_invert_tag_selection, selected_sort_mode)
	)
	%groups_tab.group_selection_changed.connect(func(_selected_groups:Array):
		selected_groups = _selected_groups
		filter_changed.emit(selected_groups, selected_tags, selected_match_all,selected_invert_tag_selection, selected_sort_mode)		
	)
	%sort_tab.option_selected.connect(func(option):
		selected_sort_mode = option
		filter_changed.emit(selected_groups, selected_tags, selected_match_all,selected_invert_tag_selection, selected_sort_mode)			
	)
	%sort_tab.close_requested.connect(toggle_tab.bind(false, %sort_tab) )
	
	#filter_changed(selected_groups:Array, selected_tags:Array, match_any_tag:bool, invert_tag_selection:bool, sort_mode:String)

func update_filter():	
	filter_changed.emit()
	
func toggle_tab(on, tab):
	tab.visible = on
	
func _input(event: InputEvent):
	if event is InputEventScreenTouch and event.pressed:
		var active_button = button_group.get_pressed_button()
		if not active_button: return
		if active_button == %tag_button:
			if not %tags_tab.get_child(0).get_global_rect().has_point(event.position) and not %tag_button.get_global_rect().has_point(event.position):
				toggle_tab(false, %tags_tab )
		if active_button == %grouping_button:
			if not %groups_tab.get_child(0).get_global_rect().has_point(event.position) and not %grouping_button.get_global_rect().has_point(event.position):
				toggle_tab(false, %groups_tab )				
		if active_button == %sort_button:
			if not %sort_tab.get_child(0).get_global_rect().has_point(event.position) and not %sort_button.get_global_rect().has_point(event.position):
				toggle_tab(false, %sort_tab )
	
