extends StateNode

# this is just for the test arena. it gives us a state where we can drive the
# fish around and see how it moves

func _entered(_fs) -> void:
	target.gravity_scale = 0
	target.set_next_linear_velocity(Vector2.LEFT * 500.0)


func _input(event: InputEvent):
	if event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("up") or event.is_action_pressed("down"):
		var v := Input.get_vector("left", "right", "up", "down")
		target.set_next_linear_velocity(v * 500.0)
