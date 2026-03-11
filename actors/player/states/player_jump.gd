class_name PlayerJumpState
extends PlayerState

const JUMP_STRENGTH = 900.0


func _entered(_from_state: StateNode) -> void:
	player.velocity += -GRAVITY_DIRECTION * JUMP_STRENGTH
	player.anim_player.play("jump", 0.1)
