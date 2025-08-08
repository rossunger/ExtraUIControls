extends Control

enum DIRECTIONS{
	LEFT, TOP, CENTER, RIGHT, BOTTOM
}
@export var direction: DIRECTIONS
@export var close_on_click_outside = true
@export var duration = 0.25
@export var relative_position = false
@export_range(0.0, 1.0, 0.025) var dimming_amount = 0.5
@export var trigger_button: Button

var tween_position:Tween
var tween_opacity:Tween
var dimmer_stylebox:= StyleBoxFlat.new()

var modal_open = false

func _process(delta):
	if tween_position and tween_position.is_running():
		%dimming_panel.global_position = Vector2(-50,-50)
		%dimming_panel.size = get_viewport_rect().size *2 
	
	
func _ready():	
	custom_minimum_size = size
	set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE if direction == DIRECTIONS.LEFT else Control.PRESET_TOP_WIDE if direction == DIRECTIONS.TOP else Control.PRESET_RIGHT_WIDE if direction == DIRECTIONS.RIGHT else Control.PRESET_BOTTOM_WIDE if direction == DIRECTIONS.RIGHT else Control.PRESET_CENTER)	
	if direction == DIRECTIONS.CENTER:
		modulate = Color(1,1,1,0)
	else:
		position = get_modal_start_position()		
	if trigger_button:
		if trigger_button.toggle_mode:		
			trigger_button.toggled.connect(func(on): 
				if on: open_modal() 
				else: close_modal()
			)
		else:
			trigger_button.pressed.connect(open_modal)
	
func get_modal_start_position():	
	if direction == DIRECTIONS.LEFT: return Vector2(-size.x,0)
	if direction == DIRECTIONS.TOP: return Vector2(0,-size.y)
	if direction == DIRECTIONS.RIGHT: return Vector2(get_viewport_rect().size.x,0)
	if direction == DIRECTIONS.BOTTOM: return Vector2(0,get_viewport_rect().size.y)

func get_modal_end_position():	
	if direction == DIRECTIONS.LEFT: return Vector2(0,0)
	if direction == DIRECTIONS.TOP: return Vector2(0,0)
	if direction == DIRECTIONS.RIGHT: return Vector2(get_viewport_rect().size.x-size.x,0)
	if direction == DIRECTIONS.BOTTOM: return Vector2(0,get_viewport_rect().size.y-size.y)	
	
func open_modal():
	visible = true	
	tween_position = create_tween()			
	if direction == DIRECTIONS.CENTER:
		tween_position.tween_property(self, "modulate", Color(1,1,1,1), duration )										
	else:
		tween_position.tween_property(self, "position" if relative_position else "global_position", get_modal_end_position(), duration )								
	
	tween_opacity = create_tween()
	tween_opacity.tween_property(%dimming_panel, "modulate", Color(1,1,1,dimming_amount), duration ).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if close_on_click_outside:
		modal_open = true

func close_modal():
	tween_position = create_tween()	
	if direction == DIRECTIONS.CENTER:
		tween_position.tween_property(self, "modulate", Color(1,1,1,0), duration )										
	else:		
		tween_position.tween_property(self, "position" if relative_position else "global_position", get_modal_start_position(), duration )								
	
	tween_opacity = create_tween()
	tween_opacity.tween_property(%dimming_panel, "modulate", Color(1,1,1,0), duration ).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _input(event):
	if modal_open and event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		if trigger_button.get_global_rect().has_point(event.position): return
		if not get_global_rect().has_point(event.position):
			close_modal()
			if trigger_button and trigger_button.toggle_mode:
				trigger_button.set_pressed_no_signal(false)
