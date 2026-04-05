extends StateNode


var bird: BirdMonster


func init_state(_machine: StateMachine, _target: Node2D) -> void:
	super.init_state(_machine, _target)
	if _target is BirdMonster:
		bird = _target
	else:
		Log.error(self, "this state needs a BirdMonster as the target to work")


func _entered(_from_state: StateNode) -> void:
	var rest_seconds := randf_range(bird.nest_min_seconds, bird.nest_max_seconds)
	Log.debug(bird, "resting for", rest_seconds, "seconds")
	var timer := get_tree().create_timer(rest_seconds)
	timer.timeout.connect(_on_timer_complete)


func _on_timer_complete() -> void:
	machine.transition_by_name("Flying")
