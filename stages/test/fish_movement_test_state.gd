extends StateNode


func _entered(_fs) -> void:
	target.gravity_scale = 0


func _input(event: InputEvent):
	if event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("up") or event.is_action_pressed("down"):
		var v := Input.get_vector("left", "right", "up", "down")
		target.set_next_linear_velocity(v * 500.0)
