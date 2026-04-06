extends BirdBaseState


func _entered(_from: StateNode) -> void:
	if not bird.carried_obj:
		Log.error(self, "no object to carry!")
		machine.transition_by_name("Flying")
		return
	bird.carried_obj.picked_up.emit(bird)
	destination = _get_random_nest().global_position

	bird.recently_carried.append(bird.carried_obj)


func _before_exit(_to: StateNode) -> void:
	bird.carried_obj.put_down.emit()
	bird.carried_obj = null


func _reached_destination() -> void:
	if _is_at_nest():
		machine.transition_by_name("Nesting")
	else:
		machine.transition_by_name("Flying")
