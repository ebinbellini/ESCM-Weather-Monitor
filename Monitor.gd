extends Control

onready var net: HTTPRequest = get_node("HTTPRequest")
onready var grid: GridContainer = get_node("scroll/grid")
onready var unparsed: Label = get_node("Unparsed")
onready var button: Button = get_node("Button")
onready var title: Label = get_node("dropdown-button/Title")
onready var dropdown_list: Control = get_node("dropdown-button/Dropdown/ScrollContainer/VBoxContainer")
onready var dropdown: Control = get_node("dropdown-button/Dropdown")
onready var spinner: VideoPlayer = get_node("spinner")

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


# Called when the node enters the scene tree for the first time.
func _ready():
	net.connect("request_completed", self, "_on_request_completed")
	button.connect("button_pressed", self, "_on_button_pressed")
	fetch_data()


func _on_button_pressed():
	# Toggle visibility of unparsed data
	unparsed.visible = not unparsed.visible


func _on_request_completed(_result, _response_code, _headers, body):
	var response: String = body.get_string_from_utf8()

	parse_metar_data(response)
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


func parse_metar_data(response: String):
	# Parse response
	var escm_pos: int = response.find(selected_base)
	response.erase(0, escm_pos)
	var item_text_pos: int = response.find('item-text">')
	response.erase(0, item_text_pos + len('item-text">'))
	var end = response.find("=</span>")
	response.erase(end, len(response) - end - 1)

	unparsed.set_text(response)

	# This contains our desired data
	var split: Array = response.split(" ")

	# Remove all previous nodes
	for child in grid.get_children():
		child.queue_free()

	# Clock
	insert_value(texture_paths[0], format_time(split[0]))

	# Auto
	if split[1] == "AUTO":
		split.remove(1)
		insert_value(texture_paths[7], "Helt automatiskt")

	# Wind
	insert_value(texture_paths[1], format_wind(split[1]))

	# Sight
	insert_value(texture_paths[2], format_sight(split[2]))

	# Weather conditions
	# Check if we have reached the temperature using regex and if so
	# then we stop expecting weather contiditions
	var temperature_regex: RegEx = RegEx.new()
	temperature_regex.compile("(M?[0-9][0-9]*\/M?[0-9][0-9]*)")
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
	var result: String =  (inp[2] + inp[3] + ":" + inp[4] + inp[5] + " UTC")
	return result


func format_wind(value: String) -> String:
	# kan ha auto före

	var ang: String = value[0] + value[1] + value[2] + "°"
	# Remove zeroes from the beginning
	while ang[0] == "0":
		ang.erase(0, 1)


	var speed = value[3] + value[4] + " knop"
	# Remove zeroes from the beginning
	if speed[0] == "0":
		speed.erase(0, 1)

	return speed + " " + ang


func format_sight(value: String) -> String:
	if value == "CAVOK":
		return "Okej sikt!"
	else:
		return value + " m"


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
	match res:
		"FG":
			res = "dimma"
		"BR":
			res = "fuktdis"
		"MIFG":
			res = "låg dimma"
		"BCFG":
			res = "hög dimbank"
		"PRFG":
			res = "mkt dimma"
		"FZFG":
			res = "underkyld dimma"
		"DZ":
			res = "duggregn"
		"FZDZ":
			res = "underkylt duggregn"
		"FZRA":
			res = "underkylt regn"
		"RA":
			res = "regn"
		"SN":
			res = "snö"
		"SNRA":
			res = "snö och regn"
		"SG":
			res = "kornsnö"
		"GR":
			res = "hagel"
		"PL":
			res = "iskorn"
		"SHRA":
			res = "regnskurar"
		"SHSN":
			res = "snöbyar"
		"SHRASN":
			res = "regn- och snöbyar"
		"SHSNRA":
			res = "snö- och regnbyar"
		"BLSN":
			res = "högt snödrev"
		"DRSN":
			res = "lågt snödrev"
		"IC":
			res = "isnålar"
		"DU":
			res = "stoft"
		"DS":
			res = "stoftstorm"
		"PO":
			res = "stoftvirvlar"
		"SA":
			res = "sand"
		"SS":
			res = "sandstorm"
		"VA":
			res = "vulkanisk aska!!"
		"FC":
			res = "tromb"
		"FU":
			res = "rök"
		"HZ":
			res = "torrdis"
		"TS":
			res = "åskväder"
		"SQ":
			res = "linjeby"
		# === Clouds below ===
		"SKC":
			res = "klar himmel"
		"NCD":
			res = "inget moln"
		"CLR":
			res = "typ klart"
		"NSC":
			res = "typ inga moln"
		"FEW":
			res = "1-2 oktas"
		"SCT":
			res = "3-4 oktas"
		"BKN":
			res = "5-7 oktas"
		"OVC":
			res = "heltäckt"
		"VV":
			res = "vertikal sikt"
		# Unknown code
		_:
			res = res

	if res == "":
		res = str(number)
	elif number != -1 and res != "":
		res = res + " " + str(100 * number) + " fot"
	if light:
		res = "lätt " + res
	if unclear:
		res = res + "?"

	# Capitalize first character
	var first = res[0]
	res.erase(0, 1)
	res = first.to_upper() + res

	return res


func format_temp(value: String) -> String:
	var res = value
	res = res.replace("M", "-")
	res = res.replace("/", " °C / ") + " °C"
	return res


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

	net.request("https://aro.lfv.se/Links/Link/ViewLink?TorLinkId=314&type=MET")


func _on_spinner_finished():
	if spinner.visible:
		spinner.play()
