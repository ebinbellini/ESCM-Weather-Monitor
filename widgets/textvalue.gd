extends Control

onready var label: Label = get_node("Label")

func _ready():
	pass


func set_value(text: String):
	label.set_text(text)
