class_name PlayerFallState
extends PlayerState


const RAGDOLL_AFTER_MS = 1000
const LANDING_DUST_SCALE = 20.0

var started_falling_at: int


func _entered(_from_state: StateNode) -> void:
	started_falling_at = Time.get_ticks_msec()
	if player.is_holding_prop:
		player.anim_player.play("fall_carry", 0.8)
	else:
		player.anim_player.play("fall", 0.8)


func _process(delta: float) -> void:
	super._process(delta)
	
	if player.ground_detector.is_colliding():
		player.puff_left_dust(LANDING_DUST_SCALE)
		player.puff_right_dust(LANDING_DUST_SCALE)

	if player.ground_detector.is_colliding() and player.ground_detector.get_collider() is Orb:
		machine.transition_by_name("Ragdoll")
	elif player.is_on_floor():
		machine.transition_by_name("Idle")
	elif Time.get_ticks_msec() > started_falling_at + RAGDOLL_AFTER_MS:
		machine.transition_by_name("Ragdoll")
