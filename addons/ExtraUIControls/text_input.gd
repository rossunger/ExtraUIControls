extends LineEdit

signal text_change_requested

enum INPUT_MODES{
	NONE, INT, FLOAT, NUMBER, EMAIL, PHONE, DATE, TIME, DATE_TIME
}

@export var filter: INPUT_MODES
var old_text

func _ready():
	old_text = text
	text_submitted.connect(func(txt):
		if pre_validate():			
			text_change_requested.emit(old_text, txt)
			old_text = text
		else:
			text = old_text			
	)
	focus_exited.connect(func():
		if pre_validate():
			text_change_requested.emit(old_text, text)
			old_text = text
		else:
			text = old_text
	)

func pre_validate()->bool:
	if filter == INPUT_MODES.INT:
		return text.is_valid_int()
	if filter == INPUT_MODES.FLOAT:
		return text.is_valid_float()
	if filter == INPUT_MODES.NUMBER:
		return text.is_valid_float() or text.is_valid_int()	
	if filter == INPUT_MODES.EMAIL:		
		return is_valid_email(text)
	if filter == INPUT_MODES.PHONE:
		return is_valid_phone(text)
	if filter == INPUT_MODES.DATE:
		return is_valid_date(text)
	if filter == INPUT_MODES.TIME:
		return is_valid_time(text)
	if filter == INPUT_MODES.DATE_TIME:
		return is_valid_datetime(text)
	return true

# ------------------------------
# EMAIL
func is_valid_email(s: String) -> bool:
	var regex = RegEx.new()
	regex.compile(r"^[\w\.-]+@[\w\.-]+\.\w+$")
	return regex.search(s) != null

# ------------------------------
# PHONE (loose international)
func is_valid_phone(s: String) -> bool:
	var regex = RegEx.new()
	regex.compile(r"^\+?[0-9\s\-\(\)]{7,20}$")
	return regex.search(s) != null

# ------------------------------
# DATE — supports:
#   YYYY-MM-DD
#   DD/MM/YYYY or DD/MM/YY
#   DD-MMM-YYYY or DD MMM YYYY
#   DD MMM, YYYY
#   9 Aug 2025
func is_valid_date(s: String) -> bool:
	var iso_str = _normalize_date(s.strip_edges())
	if iso_str == "":
		return false
	var dt := DateTime.new()
	return dt.parse_iso8601(iso_str + "T00:00:00") == OK

# ------------------------------
# TIME (HH:MM or HH:MM:SS)
func is_valid_time(s: String) -> bool:
	var regex = RegEx.new()
	regex.compile(r"^(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$")
	return regex.search(s.strip_edges()) != null

# ------------------------------
# DATETIME — date formats above + time
func is_valid_datetime(s: String) -> bool:
	s = s.strip_edges()
	# Split date and time
	var parts = s.split(" ", false, 2)
	if parts.size() < 2:
		return false
	var date_str = parts[0]
	var time_str = parts[1]
	# Sometimes time part may be after a comma in formats like "9 Aug, 2025 13:00"
	if date_str.ends_with(","):
		date_str = date_str.substr(0, date_str.length() - 1)

	var iso_date = _normalize_date(date_str)
	if iso_date == "":
		return false
	if not is_valid_time(time_str):
		return false

	var dt := DateTime.new()
	return dt.parse_iso8601(iso_date + "T" + time_str) == OK

# ------------------------------
# Helper: Convert various date formats → YYYY-MM-DD
func _normalize_date(s: String) -> String:
	var months = {
		"jan": 1, "feb": 2, "mar": 3, "apr": 4,
		"may": 5, "jun": 6, "jul": 7, "aug": 8,
		"sep": 9, "oct": 10, "nov": 11, "dec": 12
	}

	var regex = RegEx.new()

	# 1) YYYY-MM-DD
	regex.compile(r"^(\d{4})-(\d{2})-(\d{2})$")
	var m = regex.search(s)
	if m:
		return m.get_string(1) + "-" + m.get_string(2) + "-" + m.get_string(3)

	# 2) DD/MM/YYYY or DD/MM/YY
	regex.compile(r"^(\d{1,2})/(\d{1,2})/(\d{2}|\d{4})$")
	m = regex.search(s)
	if m:
		var year = int(m.get_string(3))
		if year < 100: year += 2000
		return str(year).pad_zeros(4) + "-" + m.get_string(2).pad_zeros(2) + "-" + m.get_string(1).pad_zeros(2)

	# 3) DD-MMM-YYYY or DD MMM YYYY or DD MMM, YYYY
	regex.compile(r"^(\d{1,2})[\s\-]([A-Za-z]{3})[,]?[\s\-](\d{2,4})$")
	m = regex.search(s)
	if m:
		var month = months.get(m.get_string(2).to_lower(), 0)
		if month == 0: return ""
		var year = int(m.get_string(3))
		if year < 100: year += 2000
		return str(year).pad_zeros(4) + "-" + str(month).pad_zeros(2) + "-" + m.get_string(1).pad_zeros(2)

	# 4) MMM DD, YYYY
	regex.compile(r"^([A-Za-z]{3}) (\d{1,2}), (\d{2,4})$")
	m = regex.search(s)
	if m:
		var month = months.get(m.get_string(1).to_lower(), 0)
		if month == 0: return ""
		var year = int(m.get_string(3))
		if year < 100: year += 2000
		return str(year).pad_zeros(4) + "-" + str(month).pad_zeros(2) + "-" + m.get_string(2).pad_zeros(2)

	return "" # No match
	
func reset_text():
	text = old_text
