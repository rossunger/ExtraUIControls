extends PanelContainer

signal object_tags_updated(object_name:String, active_tags:Array)

var data = {"blue_box": ["blue", "small"], "red_box": ["red", "small"]} # object: [tag1,tag2]
var tag_list = ["hidden", "red", "blue", "big", "small"]
var groups = {"color":["red", "blue"], "size":["big", "small"]}

func _ready():
	build_tree()
	%object_tree.multi_selected.connect(multi_select)
	%object_tree.nothing_selected.connect(func():
		%object_tree.deselect_all()
		%tag_picker.active_tags = []
		%tag_picker.build_tag_tree()
	)	
	%tag_picker.tag_list = tag_list
	%tag_picker.groups = groups 	 		
	%tag_picker.build_tag_tree()
	%tag_picker.tag_state_changed.connect(update_object_tags)
	%object_search.text_changed.connect(filter_objects)
	
func filter_objects(text):
	for item in %object_tree.get_root().get_children():
		item.visible = item.get_text(0).containsn(text) or text.is_empty()
	
func build_tree():
	var root: TreeItem = %object_tree.create_item()	
	for key in data.keys():
		var item = root.create_child()
		item.set_text(0, key)
		

func multi_select(item: TreeItem, column: int, selected: bool):
	if not selected: return
	var key = item.get_text(0)
	%tag_picker.active_tags = data[key]
	%tag_picker.build_tag_tree()

func update_object_tags(active_tags, _all, _not):
	var item = %object_tree.get_next_selected(null)
	while true:
		item = %object_tree.get_next_selected(item)
		if item == null: break
		var text = item.get_text(0)
		data[text] = active_tags
		object_tags_updated.emit(text, active_tags)		
