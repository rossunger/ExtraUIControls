@tool
extends Control

signal date_selected(date_dict)
# Scene nodes
@onready var month_year_label: Button = %MonthYearLabel
@onready var prev_month_button: Button = %PrevMonthButton
@onready var next_month_button: Button = %NextMonthButton
@onready var day_buttons_grid: GridContainer = %DayButtonsGrid

# Calendar state
var current_year: int
var current_month: int
var selected_day: int = -1

var day_labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
var month_names = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

func _ready():
	#if Engine.is_editor_hint(): return
	var options = ""
	for i in 200:
		options += str(1900 + i, "\n")
	%YearsSpinBox.options = options
	# Set up the calendar to the current month
	var now = Time.get_datetime_dict_from_system()
	current_year = now.year
	current_month = now.month
	
	# Only select the current day if the calendar starts on the current month
	if current_year == now.year and current_month == now.month:
		selected_day = now.day
	else:
		selected_day = -1
	
	# Theme 
	prev_month_button.theme_type_variation = theme_type_variation + "_" + "calendar_day"
	next_month_button.theme_type_variation = theme_type_variation + "_" + "calendar_day"
	month_year_label.theme_type_variation = theme_type_variation + "_" + "calendar_day"
	%confirm_year_button.theme_type_variation = theme_type_variation + "_" + "calendar_day"
	%TodayButton.theme_type_variation = theme_type_variation + "_" + "calendar_day"
	%YearsSpinBox.theme_type_variation = theme_type_variation + "_" + "years_spinbox"	
	# Connect button signals
	prev_month_button.pressed.connect(_on_prev_month_pressed)
	next_month_button.pressed.connect(_on_next_month_pressed)
	month_year_label.toggled.connect(func(on):		
		day_buttons_grid.visible = not on
		%YearsSpinBox.visible = on
		%YearsSpinBox.set_deferred("value", current_year - 1900)
		%confirm_year_button.visible = on
		#month_year_label.disabled = on
		prev_month_button.disabled = on
		next_month_button.disabled = on
		%TodayButton.disabled = on		
	)
	%confirm_year_button.pressed.connect(func():
		current_year = 1900 + %YearsSpinBox.value
		_update_calendar_view()
		month_year_label.button_pressed = false						
	)
	%TodayButton.pressed.connect(set_date.bind(Time.get_datetime_dict_from_system()))
	# Draw the initial calendar view
	_create_day_headers()
	_update_calendar_view()
	custom_minimum_size = get_combined_minimum_size()

# Helper function to get the number of days in a month (Godot 4 doesn't have this built-in)
func _get_days_in_month(year: int, month: int) -> int:
	if month == 2:
		# Check for leap year
		if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
			return 29
		else:
			return 28
	elif month in [4, 6, 9, 11]:
		return 30
	else:
		return 31

func _create_day_headers():
	# Add day of the week labels to the grid
	for day_name in day_labels:
		var label = Label.new()
		label.text = day_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_buttons_grid.add_child(label)

func _update_calendar_view():
	# Clear previous day buttons
	for child in day_buttons_grid.get_children():
		# Don't remove the day headers (which are Labels)
		if child.is_class("Button"):
			child.queue_free()

	# Update month and year label
	month_year_label.text = "%s %d" % [month_names[current_month - 1], current_year]

	# Get the weekday of the first day of the month using Godot 4.x methods
	var first_day_of_month = {
		"year": current_year,
		"month": current_month,
		"day": 1,
		"hour": 0,
		"minute": 0,
		"second": 0
	}
	var first_day_unix_time = Time.get_unix_time_from_datetime_dict(first_day_of_month)
	var first_day_datetime = Time.get_datetime_dict_from_unix_time(first_day_unix_time)
	var first_day_weekday = first_day_datetime.weekday

	# Add empty buttons for spacing until the first day of the month
	for i in range(first_day_weekday):
		var button = Button.new()
		button.text = ""
		button.theme_type_variation = theme_type_variation + "_" + "calendar_day_blank"
		button.disabled = true
		day_buttons_grid.add_child(button)

	# Add buttons for each day of the month
	var days_in_month = _get_days_in_month(current_year, current_month)
	var button_group = ButtonGroup.new()
	for day in range(1, days_in_month + 1):
		var button = Button.new()
		button.text = str(day)
		button.button_group = button_group
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE # Prevent focus from interfering with UI
		button.button_down.connect(_on_day_pressed.bind(day))
		button.theme_type_variation = theme_type_variation + "_" + "calendar_day"
		# Highlight the selected day
		if day == selected_day:
			button.theme_type_variation = theme_type_variation + "_" + "calendar_day_selected"
			
		day_buttons_grid.add_child(button)
func _on_day_pressed(day: int):
	selected_day = day
	date_selected.emit({
		"year": current_year,
		"month": current_month,
		"day": day
	})
	_update_calendar_view()

func _on_prev_month_pressed():
	current_month -= 1
	if current_month < 1:
		current_month = 12
		current_year -= 1
	selected_day = -1 # Deselect day when changing months
	_update_calendar_view()

func _on_next_month_pressed():
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
	selected_day = -1 # Deselect day when changing months
	_update_calendar_view()

# Public function to set the picker's date from an external script
func set_date(date_dict: Dictionary):
	if "year" in date_dict:
		current_year = date_dict.year
	if "month" in date_dict:
		current_month = date_dict.month
	if "day" in date_dict:
		selected_day = date_dict.day
	_update_calendar_view()
