extends Control

const active: Color = Color(1, 1, 1, 1)
const inactive: Color = Color(1, 1, 1, 0.3)

var is_selected_side_right: bool = false

onready var left_side: Button = get_node("HBox/Left");
onready var right_side: Button = get_node("HBox/Right");


func _ready():
	left_pressed()


func left_pressed():
	is_selected_side_right = false
	apply_styles()


func right_pressed():
	is_selected_side_right = true
	apply_styles()


func apply_styles():
	var lbox: StyleBoxFlat = StyleBoxFlat.new()
	var rbox: StyleBoxFlat = StyleBoxFlat.new()

	lbox.corner_radius_top_left = 16
	lbox.corner_radius_bottom_left = 16

	rbox.corner_radius_top_right = 16
	rbox.corner_radius_bottom_right = 16

	if is_selected_side_right:
		lbox.bg_color = inactive
		rbox.bg_color = active
	else:
		lbox.bg_color = active
		rbox.bg_color = inactive

	left_side.set("custom_styles/normal", lbox)
	right_side.set("custom_styles/normal", rbox)


func get_value() -> bool:
	return is_selected_side_right
