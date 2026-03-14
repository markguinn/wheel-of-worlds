class_name PlayerWalkState
extends PlayerState


func _entered(_from_state: StateNode) -> void:
	player.anim_player.play("walk", 0.4)


func _process(delta: float) -> void:
	super._process(delta)
	if is_zero_approx(_get_input_vector().x):
		machine.transition_by_name("Idle")
