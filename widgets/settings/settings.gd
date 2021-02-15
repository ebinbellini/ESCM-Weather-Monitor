extends ColorRect

signal settings_changed

onready var anim: AnimationPlayer = get_node("anim")

const animation_name: String = "display"

onready var apply_button: Button = get_node("Panel/HBoxContainer/apply")

onready var temp: Control = get_node("Panel/PanelContent/VBoxContainer/Temperature")
onready var dist: Control = get_node("Panel/PanelContent/VBoxContainer/Distance")
onready var velc: Control = get_node("Panel/PanelContent/VBoxContainer/Velocity")



func display():
	if not anim.is_playing():
		anim.play(animation_name)


func hide():
	if not anim.is_playing():
		anim.play_backwards(animation_name)


func get_settings_values() -> Array:
	var settings_values: Array = [] 
	for switch in [temp, dist, velc]:
		settings_values.append(switch.get_children()[1].get_value())

	return settings_values


func apply():
	emit_signal("settings_changed", get_settings_values())
	hide()
