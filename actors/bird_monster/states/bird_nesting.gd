extends BirdBaseState


func _entered(_from_state: StateNode) -> void:
	var rest_seconds := randf_range(bird.nest_min_seconds, bird.nest_max_seconds)
	Log.debug(bird, "resting for", rest_seconds, "seconds")
	var timer := get_tree().create_timer(rest_seconds)
	timer.timeout.connect(_on_timer_complete)


func _on_timer_complete() -> void:
	machine.transition_by_name("Flying")


func _process(_delta: float) -> void:
	pass
