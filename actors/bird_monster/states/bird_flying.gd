extends BirdBaseState

const HORIZ_RANGE = 1000.0
const VERT_RANGE = 400.0
const DEST_THRESHOLD = 50.0

var starting_pos: Vector2


func _entered(_from_state: StateNode) -> void:
	starting_pos = bird.global_position
	_choose_destination()


func _get_random_point() -> Vector2:
	var min_x := starting_pos.x - HORIZ_RANGE
	var max_x := starting_pos.x + HORIZ_RANGE
	var min_y := starting_pos.y - VERT_RANGE
	var max_y := starting_pos.y + VERT_RANGE

	for nest in bird.nests:
		min_x = min(min_x, nest.global_position.x - HORIZ_RANGE)
		max_x = min(max_x, nest.global_position.x + HORIZ_RANGE)
		min_y = min(min_y, nest.global_position.y - VERT_RANGE)
		max_y = min(max_y, nest.global_position.y + VERT_RANGE)

	return Vector2(
		randf_range(min_x, max_x),
		randf_range(min_y, max_y),
	)


func _choose_destination() -> void:
	var roll := randf()
	Log.debug(bird, "rolled for next move", roll)
	if roll <= bird.nest_probability and bird.nests.size() > 0:
		destination = _get_random_nest().global_position
	elif roll <= bird.nest_probability + bird.attack_probability:
		machine.transition_by_name("Attacking")
		return
	else:
		destination = _get_random_point()
	Log.debug(bird, "new destination", destination)


func _reached_destination() -> void:
	if _is_at_nest():
		machine.transition_by_name("Nesting")
	else:
		_choose_destination()
