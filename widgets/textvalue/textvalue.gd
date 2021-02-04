extends Control

onready var label: Label = get_node("Label")
onready var txrc: TextureRect = get_node("TextureRect")

func _ready():
	pass


func set_value(text: String):
	label.set_text(text)


func set_texture(txtr: Texture):
	txrc.texture = txtr
	
