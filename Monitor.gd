extends Control

onready var net: HTTPRequest = get_node("HTTPRequest")

# Called when the node enters the scene tree for the first time.
func _ready():
	net.connect("request_completed", self, "_on_request_completed")
	net.request("https://aro.lfv.se/Links/Link/ViewLink?TorLinkId=314&type=MET")


func _on_request_completed(_result, _response_code, _headers, body):
	var response: string = body.get_string_from_utf8()
	var escm_pos: int = response.find("ESCM")
	print(escm_pos)

