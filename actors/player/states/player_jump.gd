class_name PlayerJumpState
extends PlayerState

const JUMP_STRENGTH = 900.0
const CARRYING_JUMP_STRENGTH = 600.0
const WIND_UP_TIME = 0.3

func _entered(_from_state: StateNode) -> void:
	if player.is_holding_prop:
		player.anim_player.play("jump_carry", 0.1)
	else:
		player.anim_player.play("jump", 0.1)
		
	var old_horizontal_speed := horizontal_speed
	horizontal_speed = 0
	player.velocity.x /= 2
	await get_tree().create_timer(WIND_UP_TIME).timeout
	horizontal_speed = old_horizontal_speed
	
	if player.is_holding_prop:
		player.velocity += -GRAVITY_DIRECTION * CARRYING_JUMP_STRENGTH
	else:
		player.velocity += -GRAVITY_DIRECTION * JUMP_STRENGTH

func _process(delta: float) -> void:
	super._process(delta)
	# If they let up on the jump button early we want to end the jump a little 
	# earlier so we slow them down gently but not immediately
	if not Input.is_action_pressed("jump"):
		player.velocity.y = move_toward(player.velocity.y, 0.0, JUMP_STRENGTH * delta * 1.5)
