extends BirdBaseState


# This state is just a moment of pause before the bird flies off with your prop
# If we have time we should make it struggle a little bit, either in the animation
# or just positioning.

const STRUGGLE_RANGE = 80.0

var struggle_time_ms: int


func _entered(_from: StateNode) -> void:
	struggle_time_ms = roundi(randf_range(bird.pickup_pause_secounds / 2.0, bird.pickup_pause_secounds) * 1000)
	_pick_destination()


func _process(delta: float) -> void:
	super._process(delta)
	if GameManager.now_ms() > machine.last_state_change_ms + struggle_time_ms:
		machine.transition_by_name.call_deferred("Carrying")


func _reached_destination() -> void:
	_pick_destination()


func _pick_destination() -> void:
	if not bird.carried_obj:
		return
	destination = bird.carried_obj.global_position + Vector2(
		randf_range(-STRUGGLE_RANGE, STRUGGLE_RANGE),
		randf_range(-STRUGGLE_RANGE, -STRUGGLE_RANGE / 2.0),
	)
