class_name PlayerFallState
extends PlayerState


const RAGDOLL_AFTER_MS = 1000
const LANDING_DUST_SCALE = 20.0

var started_falling_at: int


func _entered(_from_state: StateNode) -> void:
	started_falling_at = GameManager.now_ms()
	if player.is_holding_prop:
		player.anim_player.play("fall_carry", 0.8)
	else:
		player.anim_player.play("fall", 0.8)


func _process(delta: float) -> void:
	super._process(delta)

	if transitioning_out:
		return
	elif player.ground_detector.is_colliding() and player.ground_detector.get_collider() is Orb:
		_land_on_orb(player.ground_detector.get_collider(), player.ground_detector.get_collision_point(), player.ground_detector.get_collision_normal())
	elif player.is_on_floor():
		machine.transition_by_name("Idle")
	elif GameManager.now_ms() > started_falling_at + RAGDOLL_AFTER_MS:
		machine.transition_by_name("Ragdoll")


func _land_on_orb(orb: Orb, collision_point: Vector2, collision_normal: Vector2) -> void:
	#machine.transition_by_name("Ragdoll")
	Log.info(self, "boing", collision_normal, collision_point)
	orb.squisher.scale.y = 1.0 - smoothstep(0.0, 800.0, player.velocity.length()) * 0.5
	#orb.apply_impulse(player.velocity.normalized(), collision_point - orb.global_position)
	orb.apply_central_impulse(player.velocity.normalized())
	player.velocity = collision_normal * 800.0
	player.puff_left_dust(3.0)
	player.puff_right_dust(3.0)
	started_falling_at = GameManager.now_ms()
	

func transition_before_exit(to_state: StateNode) -> void:
	if player.ground_detector.is_colliding():
		player.puff_left_dust(LANDING_DUST_SCALE)
		player.puff_right_dust(LANDING_DUST_SCALE)
	if to_state.name != "Ragdoll" and absf(player.avg_recent_velocity.y) > 150.0:
		if player.is_holding_prop:
			player.anim_player.play("land_while_carrying", 0.1)
		else:
			player.anim_player.play("land_after_fall", 0.1)
		player.velocity.x /= 2
		await player.anim_player.animation_finished
