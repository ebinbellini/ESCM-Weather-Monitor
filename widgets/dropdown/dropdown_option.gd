extends ColorRect

signal pressed

onready var label: Label = get_node("Label")


func set_value(value: String):
	label.set_text(value)


func get_value() -> String:
	return label.text


func _pressed():
	emit_signal("pressed", label.text)
