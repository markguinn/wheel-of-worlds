class_name PlayerFallState
extends PlayerState


const RAGDOLL_AFTER_MS = 1500
const LANDING_DUST_SCALE = 20.0

var started_falling_at: int


func _entered(_from_state: StateNode) -> void:
	started_falling_at = GameManager.now_ms()
	if player.is_holding_prop:
		player.anim_player.play("fall_carry", 0.8)
	else:
		player.anim_player.play("fall", 0.8)


func _is_squishable(node: Node2D) -> bool:
	return node.has_method("squish")


func _process(delta: float) -> void:
	super._process(delta)

	if transitioning_out:
		return
	if player.ground_detector.is_colliding() and _is_squishable(player.ground_detector.get_collider()):
		_land_on_squishable(player.ground_detector.get_collider(), player.ground_detector.get_collision_point(), player.ground_detector.get_collision_normal())
	elif ground_detector_l.is_colliding() and ground_detector_l.get_collider() is Orb:
		_land_on_squishable(ground_detector_l.get_collider(), ground_detector_l.get_collision_point(), ground_detector_l.get_collision_normal())
	elif ground_detector_r.is_colliding() and ground_detector_r.get_collider() is Orb:
		_land_on_squishable(ground_detector_r.get_collider(), ground_detector_r.get_collision_point(), ground_detector_r.get_collision_normal())
	if player.is_on_floor():
		machine.transition_by_name("Idle")
	elif GameManager.now_ms() > started_falling_at + RAGDOLL_AFTER_MS:
		machine.transition_by_name("Ragdoll")


func _land_on_squishable(obj: Node2D, collision_point: Vector2, collision_normal: Vector2) -> void:
	if GameManager.rate_limit(100, "player-squish"):
		return
	
	var impact_velocity: Vector2 = player.history_buffer.get_average_velocity()
	Log.debug(
		player, 
		"bouncing on squishable", 
		obj, 
		impact_velocity,
		collision_normal, 
		collision_point
	)

	# squish the orb and give it a little push to the side if you hit off center
	var kickback: Vector2 = obj.squish(impact_velocity, collision_point, collision_normal)
	
	# this version causes the orb to spin too much
	#orb.apply_impulse(player.velocity.normalized(), collision_point - orb.global_position)
	# this version almost never moves horizontally
	#orb.apply_central_impulse(player.velocity.normalized())
	# this is a nice mix of horizontal and vertical movement
	if obj.has_method("apply_impulse"):
		obj.apply_impulse(-collision_normal * 3.0, collision_point - obj.global_position)

	# launch the player. we don't move back to jump because it
	# retriggers the animation and wants to set the velocity itself
	# it'd be nice to add a quicker jump animation or something we could trigger
	# here, and it'd be cool if you moved down just a little bit more as the orb
	# squishes - so room for folks to tweak this if they want
	player.velocity = kickback
	player.puff_left_dust(LANDING_DUST_SCALE)
	player.puff_right_dust(LANDING_DUST_SCALE)
	
	if not kickback.is_zero_approx():
		# without this you end up ragdolling almost every time
		started_falling_at = GameManager.now_ms()
	else:
		player.apply_floor_snap()
		machine.transition_by_name("Idle")
	

func transition_before_exit(to_state: StateNode) -> void:
	if player.ground_detector.is_colliding():
		player.puff_left_dust(LANDING_DUST_SCALE)
		player.puff_right_dust(LANDING_DUST_SCALE)
	if to_state.name != "Ragdoll" and absf(player.history_buffer.get_average_velocity().y) > 150.0:
		if player.is_holding_prop:
			player.anim_player.play("land_while_carrying", 0.1)
		else:
			player.anim_player.play("land_after_fall", 0.1)
		player.velocity.x /= 2
		await player.anim_player.animation_finished
