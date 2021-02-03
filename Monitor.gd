extends Control

onready var net: HTTPRequest = get_node("HTTPRequest")
onready var clock: Control = get_node("t1/clock")
onready var wind: Control = get_node("t1/clock")
onready var cash: Control = get_node("t1/sight")
onready var clouds: Control = get_node("t2/clouds")
onready var clouds2: Control = get_node("t2/clouds2")
onready var temp: Control = get_node("t2/temp")
onready var preassure: Control = get_node("t3/preassure")

	
var nodes: Array = []

#var textures = [
	#preload("res://imgs/clock.svg"),
	#preload("res://imgs/wind.svg"),
	#preload("res://imgs/eye.svg"),
	#preload("res://imgs/cloud.svg"),
	#preload("res://imgs/temp.svg"),
	#preload("res://imgs/gauge.svg")
#]

var texture_paths = [
	"res://imgs/clock.svg",
	"res://imgs/wind.svg",
	"res://imgs/eye.svg",
	"res://imgs/cloud.svg",
	"res://imgs/temp.svg",
	"res://imgs/gauge.svg"
]


# Called when the node enters the scene tree for the first time.
func _ready():
	nodes = [clock, wind, cash, clouds, temp, preassure]
	net.connect("request_completed", self, "_on_request_completed")
	fetch_data()


func _on_request_completed(_result, _response_code, _headers, body):
	var response: String = body.get_string_from_utf8()
	var escm_pos: int = response.find("ESCM")
	response.erase(0, escm_pos)
	var item_text_pos: int = response.find('item-text">')
	response.erase(0, item_text_pos + len('item-text">'))
	var end = response.find("</span>")
	response.erase(end, len(response) - end - 1)
	var split: Array = response.split(" ")

	# TODO figure out dynamically which category a value belongs to
	for i in range(len(nodes)):
		print(str(i) + " " + split[i])

		var texture = ImageTexture.new()
		var image = Image.new()
		image.load(texture_paths[i])
		texture.create_from_image(image)

		nodes[i].set_value(split[i])
		nodes[i].set_texture(texture)


func fetch_data():
	net.request("https://aro.lfv.se/Links/Link/ViewLink?TorLinkId=314&type=MET")
