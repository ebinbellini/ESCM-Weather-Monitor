extends Button

signal button_pressed

const start1: Color = Color(0.2, 0.2, 0.7)
const start2: Color = Color(0.1, 0.1, 0.6)
const hovered1: Color = Color(0.3, 0.3, 0.8)
const hovered2: Color = Color(0.3, 0.3, 0.6)

var color1: Color = start1
var color2: Color = start2
var is_hovered: bool = false
var is_pressed: bool = false

const sections: float = 48.0
const transition_time: float = 0.2

onready var tween: Tween = get_node("Tween")
onready var anim: AnimationPlayer = get_node("anim")


func _ready():
	connect("mouse_entered", self, "move_gradient")
	connect("mouse_exited", self, "reset_gradient")
	tween.connect("tween_all_completed", self, "tween_done")
	connect("button_down", self, "pressed")
	connect("button_up", self, "released")


func _process(_delta: float):
	update()


func pressed():
	if not is_pressed:
		emit_signal("button_pressed")
		is_pressed = true
		anim.playback_speed = 1
		anim.play("pressed")


func released():
	if is_pressed:
		is_pressed = false
		anim.play_backwards("pressed")


func move_gradient():
	if not is_hovered:
		is_hovered = true
		tween.stop_all()
		tween.interpolate_property(self, "color1",
			color1, hovered1, transition_time,
			Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.interpolate_property(self, "color2",
			color2, hovered2, transition_time,
			Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.start()
		set_process(true)


func reset_gradient():
	if is_hovered:
		is_hovered = false
		tween.stop_all()
		tween.interpolate_property(self, "color1",
			color1, start1, transition_time,
			Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.interpolate_property(self, "color2",
			color2, start2, transition_time,
			Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.start()
		set_process(true)


func _draw():
	var size: Vector2 = rect_size
	
	# Divide gradient into 32 rectangles
	for i in range(sections):
		color2.a = i / sections
		var color: Color = color1.blend(color2)
		var rect: Rect2 = Rect2(Vector2(i * size.x / sections, 0), Vector2(size.x / sections,  size.y))
		draw_rect(rect, color)
		

func tween_done():
	set_process(false)
