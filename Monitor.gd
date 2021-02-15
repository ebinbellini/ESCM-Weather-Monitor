extends Control

onready var net: HTTPRequest = get_node("HTTPRequest")
onready var grid: GridContainer = get_node("hide_dropdown/scroll/grid")
onready var unparsed: Label = get_node("Unparsed")
onready var raw_data_button: Button = get_node("ShowRawButton")
onready var title: Label = get_node("dropdown-button/Title")
onready var dropdown_list: Control = get_node("dropdown-button/Dropdown/ScrollContainer/VBoxContainer")
onready var dropdown: Control = get_node("dropdown-button/Dropdown")
onready var spinner: VideoPlayer = get_node("spinner")
onready var settings: Control = get_node("Settings")

var textvalue_res: Resource = preload("res://widgets/textvalue/textvalue.tscn")
var dropdown_option_res: Resource = preload("res://widgets/dropdown/dropdown_option.tscn")

const texture_paths = [
	"res://imgs/clock.svg",
	"res://imgs/wind.svg",
	"res://imgs/eye.svg",
	"res://imgs/cloud.svg",
	"res://imgs/temp.svg",
	"res://imgs/gauge.svg",
	"res://imgs/info.svg",
	"res://imgs/robot.svg",
	"res://imgs/vertical visibility.svg",
	"res://imgs/wind variation.svg",
]

const cloud_codes = [
	"SKC",
	"NCD",
	"CLR",
	"NSC",
	"FEW",
	"SCT",
	"BKN",
	"OVC",
	"VV",
]

var selected_base: String = "ESCM"

var selected_settings: Array = [false, false, false]


# Called when the node enters the scene tree for the first time.
func _ready():
	net.connect("request_completed", self, "_on_request_completed")
	raw_data_button.connect("button_pressed", self, "toggle_raw_data")
	settings.connect("settings_changed", self, "settings_changed")
	fetch_data()


func settings_changed(new_settings: Array):
	selected_settings = new_settings
	var data = unparsed.get_text()
	if data != "Loading...":
		parse_metar_data(data)


func toggle_raw_data():
	# Toggle visibility of unparsed data
	unparsed.visible = not unparsed.visible


func _on_request_completed(_result, _response_code, _headers, body):
	var response: String = body.get_string_from_utf8()

	var metar_string: String = strip_metar_string(response)
	unparsed.set_text(metar_string)

	parse_metar_data(metar_string)
	parse_bases(response)
	spinner.visible = false


func parse_bases(response: String):
	# Store all bases in the array named "bases"
	var search: String = 'item-header">'
	var bases: Array = []

	var base_pos: int = response.find(search)
	# Skip first
	response.erase(0, base_pos + len(search))
	base_pos = response.find(search)

	while base_pos != -1:
		var base: String = "ICAO"
		response.erase(0, base_pos + len(search))

		for i in range(4):
			base[i] = response[i]

		bases.append(base)

		base_pos = response.find(search)
	
	# Now we have the bases

	# Remove old bases from dropdown
	for child in dropdown_list.get_children():
		child.queue_free()

	# Put all the bases in the dropdown menu
	for base in bases:
		var option: Control = dropdown_option_res.instance()	
		dropdown_list.add_child(option)
		option.set_value(base)
		option.connect("pressed", self, "base_selected")


func base_selected(base: String):
	selected_base = base
	fetch_data()
	title.set_text(base)
	dropdown.hide()


func strip_metar_string(response: String) -> String:
	var base_pos: int = response.find(selected_base)
	response.erase(0, base_pos)
	var item_text_pos: int = response.find('item-text">')
	response.erase(0, item_text_pos + len('item-text">'))
	var end = response.find("=</span>")
	response.erase(end, len(response) - end - 1)
	return response


func parse_metar_data(metar_string: String):
	# This contains our desired data
	var split: Array = metar_string.split(" ")

	# Remove all previous nodes
	for child in grid.get_children():
		child.queue_free()

	# Clock
	insert_value(texture_paths[0], format_time(split[0]))

	# Auto
	if split[1] == "AUTO":
		split.remove(1)
		insert_value(texture_paths[7], tr("FULLY_AUTO"))

	# Wind
	insert_value(texture_paths[1], format_wind(split[1]))

	# Wind variation
	var variation_regex: RegEx = RegEx.new()
	variation_regex.compile("^([0-9]{3}V[0-9]{3})$")
	if variation_regex.search(split[2]):
		insert_value(texture_paths[9], format_wind_variation(split[2]))
		split.remove(2)

	# Sight
	insert_value(texture_paths[2], format_sight(split[2]))

	# Weather conditions
	# Check if we have reached the temperature using regex and if so
	# then we stop expecting weather contiditions
	var temperature_regex: RegEx = RegEx.new()
	temperature_regex.compile("^(M?[0-9][0-9]*\/M?[0-9][0-9]*)$")
	while not temperature_regex.search(split[3]) and len(split) > 5:
		# Figure out is code is for clouds
		var cloud: bool = false
		for code in cloud_codes:
			if split[3].find(code) != -1:
				cloud = true

		if split[3].find("VV") != -1:
			insert_value(texture_paths[8], format_weather(split[3]))
		elif cloud: 
			insert_value(texture_paths[3], format_weather(split[3]))
		else:
			insert_value(texture_paths[6], format_weather(split[3]))

		split.remove(3)

	# Temp
	if temperature_regex.search(split[3]):
		insert_value(texture_paths[4], format_temp(split[3]))
		split.remove(3)

	while len(split) > 3:
		if split[3][0] == "Q":
			# Pressure
			insert_value(texture_paths[5], format_pressure(split[3]))
		else:
			# Other information
			insert_value(texture_paths[6], split[3])
		split.remove(3)


func insert_value(path: String, value: String):
	var node = textvalue_res.instance()
	grid.add_child(node)
	node.set_value(value)
	node.set_texture(load(path))


func format_time(inp: String) -> String:
	var result: String = (inp[2] + inp[3] + ":" + inp[4] + inp[5] + " " + tr("UTC_TIME"))
	return result


func format_wind(value: String) -> String:
	var ang: String = value[0] + value[1] + value[2] + "°"

	# Remove zeroes from the beginning
	while ang[0] == "0":
		ang.erase(0, 1)


	var speed = value[3] + get_velocity_format_from_knots(int(value[4]))
	# Remove zeroes from the beginning
	if speed[0] == "0":
		speed.erase(0, 1)

	return speed + " " + ang

	
func format_wind_variation(value: String) -> String:
	var split = value.split("V")

	# Remove zeroes
	for i in range(2):
		while split[i][0] == "0":
			split[i] = split[i].trim_prefix("0")

	return split[0] + "°" + tr("FROM_TO") + split[1] + "°"


func format_sight(value: String) -> String:
	if value == "CAVOK":
		return tr("OK_VISIBILITY")
	else:
		return get_distance_format_from_feet(int(value))


func format_weather(value: String) -> String:
	var res: String = value
	var light: bool = false
	var unclear: bool = false
	var number: int = -1

	# Check for - in front
	if res[0] == "-":
		res.erase(0, 1)
		light = true

	# Check for ///
	var index: int = res.find("/")
	while index != -1:
		res.erase(index, 1)
		unclear = true
		index = res.find("/")


	var find_number: RegEx = RegEx.new()
	find_number.compile("[0-9]+")
	var result: RegExMatch = find_number.search(res)
	if result != null:
		var result_str: String = result.get_string()
		index = res.find(result_str)
		res.erase(index, len(result_str))
		number = int(result.get_string())

	# Translate
	res = tr(res)

	if res == "":
		res = str(number)
	elif number != -1 and res != "":
		res = res + " " + get_distance_format_from_meters(100 * number)
	if light:
		res = tr("LIGHT") + " " + res
	if unclear:
		res = res + "?"

	# Capitalize first character
	var first = res[0]
	res.erase(0, 1)
	res = first.to_upper() + res

	return res


func format_temp(value: String) -> String:
	value = value.replace("M", "-")
	var split: Array = value.split("/")
	
	return get_temperature_format_from_celcius(int(split[0])) + " / " + get_temperature_format_from_celcius(int(split[1]))


func format_pressure(value: String) -> String:
	# Remove Q
	value.erase(0, 1)
	# Remove new line
	value.erase(4, 1)

	return value + " hPa"


func fetch_data():
	for child in grid.get_children():
		child.queue_free()

	spinner.visible = true
	spinner.play()

	net.request("https://weather.ebinbellini.top/weather-data")


func _on_spinner_finished():
	if spinner.visible:
		spinner.play()


func get_temperature_format_from_celcius(celcius: int) -> String:
	if selected_settings[0]:
		return str(celcius * 1.8 + 32) + " °F"
	else:
		return str(celcius) + " °C"


func get_distance_format_from_feet(feet: float) -> String:
	if selected_settings[1]:
		return str(round(feet)) + " " + tr("FEET")
	else:
		return str(round(feet / 3.2808)) + " " + tr("METER")


func get_distance_format_from_meters(meters: float) -> String:
	return get_distance_format_from_feet(meters * 3.2808)


func get_velocity_format_from_knots(knots: int) -> String:
	if selected_settings[2]:
		return str(knots) + " " + tr("KNOTS")
	else:
		return str(round(knots * 0.514444)) + " " + tr("MPS")
