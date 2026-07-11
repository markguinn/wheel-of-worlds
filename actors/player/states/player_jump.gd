class_name PlayerJumpState
extends PlayerState

const WIND_UP_TIME = 0.2
const RAGDOLL_SECONDS = 0.2
const JUMP_DAMP = 4.0

@export var jump_strength := 1200.0
@export var carrying_jump_strength := 1000.0


func _entered(from_state: StateNode) -> void:
	if from_state.name == "Ragdoll":
		return
	if player.is_holding_prop:
		player.anim_player.play("jump_carry", 0.1)
	else:
		player.anim_player.play("jump", 0.1)

	var old_horizontal_speed := horizontal_speed
	horizontal_speed = 0
	player.velocity.x /= 2.0
	await get_tree().create_timer(WIND_UP_TIME).timeout
	horizontal_speed = old_horizontal_speed
	
	if player.is_holding_prop:
		player.velocity.y = -GRAVITY_DIRECTION.y * carrying_jump_strength * player.jump_multiplier
	else:
		player.velocity.y = -GRAVITY_DIRECTION.y * jump_strength * player.jump_multiplier


func _process(delta: float) -> void:
	super._process(delta)
	# If they let up on the jump button early we want to end the jump a little 
	# earlier so we slow them down gently but not immediately
	if not Input.is_action_pressed("jump"):
		player.velocity.y = move_toward(player.velocity.y, 0.0, jump_strength * delta * JUMP_DAMP)
	# every now and then you land on the ground at exactly the height of a jump
	# and you can get stuck in jump mode. this is just a fallback
	if player.is_on_floor() and GameManager.now_ms() > machine.last_state_change_ms + 1000:
		machine.transition_by_name.call_deferred("Idle")
