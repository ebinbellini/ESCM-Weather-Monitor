extends Control

onready var anim: AnimationPlayer = get_node("ScrollContainer/anim")

func toggle_visibility():
	if not visible:
		display()
	else:
		hide()


func display():
	anim.play("display")


func hide():
	if visible:
		anim.play_backwards("display")
