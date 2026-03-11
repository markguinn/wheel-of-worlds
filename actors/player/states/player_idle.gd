class_name PlayerIdleState
extends PlayerState


func _entered(_from_state: StateNode) -> void:
	if player and player.anim_player:
		player.anim_player.play("idle", 0.4)


func _process(delta: float) -> void:
	super._process(delta)

	if not is_zero_approx(_get_input_vector().x):
		machine.transition_by_name("Walk")
