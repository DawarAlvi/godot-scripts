extends Node

@export var enabled := true

var steer_touch_input:Vector2

func _unhandled_input(event):
	if not enabled: return
	if event is InputEventScreenTouch:
		if event.position.x < get_viewport().get_visible_rect().size.x / 2:
			if event.pressed:
				steer_touch_input.x = 1
			elif steer_touch_input.x == 1:
				steer_touch_input.x = 0
		else:
			if event.pressed:
				steer_touch_input.x = -1
			elif steer_touch_input.x == -1:
				steer_touch_input.x = 0
