class_name PlayerJumpState
extends PlayerState

const JUMP_STRENGTH = 900.0


func _entered(_from_state: StateNode) -> void:
	player.velocity += -GRAVITY_DIRECTION * JUMP_STRENGTH
	if player.is_holding_prop:
		player.anim_player.play("jump_carry", 0.1)
	else:
		player.anim_player.play("jump", 0.1)
