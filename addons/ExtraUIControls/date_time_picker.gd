@tool
extends Control

signal datetime_changed(datetime_dict)

enum ORDERS {
	DAY_MONTH_YEAR,
	MONTH_DAY_YEAR,
	YEAR_MONTH_DAY,
}
@export var font_size = 16:
	set(val):
		if font_size == val: return
		font_size = val
		if not is_node_ready(): return
		%YearSpinBox.font_size = font_size
		%MonthSpinBox.font_size = font_size
		%DaySpinBox.font_size = font_size
		%HourSpinBox.font_size = font_size
		%MinuteSpinBox.font_size = font_size

@export var show_buttons = false:
	set(val):
		if show_buttons == val: return
		show_buttons = val
		if not is_node_ready(): return
		%YearSpinBox.show_buttons = show_buttons
		%MonthSpinBox.show_buttons = show_buttons
		%DaySpinBox.show_buttons = show_buttons
		%HourSpinBox.show_buttons = show_buttons
		%MinuteSpinBox.show_buttons = show_buttons

@export var show_month_as_text = true:
	set(val):
		if show_month_as_text == val: return
		show_month_as_text = val
		if not is_node_ready(): return
		set_month_options()
		
@export var order: ORDERS:
	set(val):
		if order == val: return
		order = val
		if not is_node_ready(): return
		set_order()

@onready var year_spinbox: Control = %YearSpinBox
@onready var month_spinbox: Control = %MonthSpinBox
@onready var day_spinbox: Control = %DaySpinBox
@onready var hour_spinbox: Control = %HourSpinBox
@onready var minute_spinbox: Control = %MinuteSpinBox
@onready var now_button: Control = %NowButton

const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

func set_order():
	var hbox = $HBoxContainer
	if order == ORDERS.DAY_MONTH_YEAR:
		hbox.move_child(%YearSpinBox, 0)
		hbox.move_child(%MonthSpinBox, 0)
		hbox.move_child(%DaySpinBox, 0)
	elif order == ORDERS.MONTH_DAY_YEAR:
		hbox.move_child(%YearSpinBox, 0)
		hbox.move_child(%DaySpinBox, 0)
		hbox.move_child(%MonthSpinBox, 0)
	elif order == ORDERS.YEAR_MONTH_DAY:
		hbox.move_child(%DaySpinBox, 0)
		hbox.move_child(%MonthSpinBox, 0)
		hbox.move_child(%YearSpinBox, 0)
func set_month_options():
	var options = ""
	for i in 12:
		if not show_month_as_text:
			options += str(i + 1, "\n")
		else:
			options += str(months[i], "\n")
	%MonthSpinBox.options = options

func _ready():
	var options = ""
	for i in 200:
		options += str(1900 + i, "\n")
	
	%YearSpinBox.options = options
	set_month_options()
	options = ""
	for i in 31:
		options += str(i + 1, "\n")
	
	%DaySpinBox.options = options
	options = ""
	for i in 24:
		options += str(i, "\n")
	
	%HourSpinBox.options = options
	options = ""
	for i in 60:
		options += str(i, "\n")

	%MinuteSpinBox.options = options
	# Connect signals
	year_spinbox.value_changed.connect(_on_value_changed)
	month_spinbox.value_changed.connect(_on_value_changed)
	day_spinbox.value_changed.connect(_on_value_changed)
	hour_spinbox.value_changed.connect(_on_value_changed)
	minute_spinbox.value_changed.connect(_on_value_changed)
	now_button.pressed.connect(_on_now_button_pressed)

	set_to_now()	
	set_order()
		
func _on_value_changed(value):
	emit_datetime_changed()

func _on_now_button_pressed():
	set_to_now()

func set_to_now():
	var now = Time.get_datetime_dict_from_system()
	year_spinbox.value = now.year - 1900
	month_spinbox.value = now.month - 1
	day_spinbox.value = now.day - 1
	hour_spinbox.value = now.hour
	minute_spinbox.value = now.minute
	emit_datetime_changed()

func get_datetime() -> Dictionary:
	return {
		"year": year_spinbox.value,
		"month": month_spinbox.value,
		"day": day_spinbox.value,
		"hour": hour_spinbox.value,
		"minute": minute_spinbox.value
	}

func set_datetime(datetime_dict: Dictionary):
	if "year" in datetime_dict: year_spinbox.value = datetime_dict.year - 1900
	if "month" in datetime_dict: month_spinbox.value = datetime_dict.month - 1
	if "day" in datetime_dict: day_spinbox.value = datetime_dict.day - 1
	if "hour" in datetime_dict: hour_spinbox.value = datetime_dict.hour
	if "minute" in datetime_dict: minute_spinbox.value = datetime_dict.minute
	emit_datetime_changed()

func emit_datetime_changed():
	emit_signal("datetime_changed", get_datetime())
