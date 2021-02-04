extends Control

onready var anim: AnimationPlayer = get_node("ScrollContainer/anim")
onready var timer: Timer = get_node("Timer")

var changing_allowed: bool = false


func toggle_visibility():
	if modulate.a < 0.1:
		display()
	else:
		hide()


func display():
	changing_allowed = false
	timer.start()
	anim.play("display")


func hide():
	if visible && changing_allowed:
		anim.play_backwards("display")


func allow_changing():
	# Avoid changing immediately after displaying
	changing_allowed = true
