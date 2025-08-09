class_name DateTime extends Object

## Parses date and time from a string.
## Supports formats like "YYYY-MM-DD", "DD/MM/YYYY", "HH:MM", "MM-DD-YYYY HH:MM".
## Returns a Dictionary with "year", "month", "day", "hour", "minute".
## Returns null if parsing fails.
static func parse_datetime(text: String) -> Dictionary:
	var parsed_data = {
		"year": -1, "month": -1, "day": -1,
		"hour": -1, "minute": -1
	}
	
	# Regex patterns for different formats
	var patterns = [
		"^(?<year>\\d{4})-(?<month>\\d{2})-(?<day>\\d{2})$", # YYYY-MM-DD
		"^(?<day>\\d{2})/(?<month>\\d{2})/(?<year>\\d{4})$", # DD/MM/YYYY
		"^(?<month>\\d{2})/(?<day>\\d{2})/(?<year>\\d{4})$", # MM/DD/YYYY
		"^(?<hour>\\d{2}):(?<minute>\\d{2})$",               # HH:MM
		"^(?<year>\\d{4})-(?<month>\\d{2})-(?<day>\\d{2})\\s(?<hour>\\d{2}):(?<minute>\\d{2})$", # YYYY-MM-DD HH:MM
		"^(?<day>\\d{2})/(?<month>\\d{2})/(?<year>\\d{4})\\s(?<hour>\\d{2}):(?<minute>\\d{2})$"  # DD/MM/YYYY HH:MM
	]

	for pattern in patterns:
		var regex = RegEx.new()
		if regex.compile(pattern) == OK:
			var result = regex.search(text.strip_edges())
			if result:
				var groups = result.get_named_groups()
				if "year" in groups: parsed_data.year = int(groups.year)
				if "month" in groups: parsed_data.month = int(groups.month)
				if "day" in groups: parsed_data.day = int(groups.day)
				if "hour" in groups: parsed_data.hour = int(groups.hour)
				if "minute" in groups: parsed_data.minute = int(groups.minute)
				return parsed_data
	return {}
