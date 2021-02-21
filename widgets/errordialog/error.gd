extends ColorRect

signal retry

onready var retry_button: Button = get_node("Panel/PanelContent/retry")
onready var error_label: Label = get_node("Panel/PanelContent/errortext")
onready var anim: AnimationPlayer = get_node("anim")

const animation_name: String = "display"


func show_error(err: String):
	error_label.text = err
	anim.play(animation_name)


func hide():
	anim.play_backwards(animation_name)


func retry():
	emit_signal("retry")
	hide()
