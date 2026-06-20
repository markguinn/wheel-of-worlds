extends ShadowMonsterBaseState


func _process(delta: float) -> void:
	if not monster:
		return
	
	monster.arm.arm_global_position = monster.global_position
	
	if monster.target_dist < monster.target_warning_distance and GameManager.now_ms() > entered_at + monster.alert_cooldown_ms:
		machine.transition_by_name.call_deferred("Alert")
	elif monster.primary_light and monster.primary_light_dist < monster.lightsource_distance_tolerated:
		machine.transition_by_name.call_deferred("Flee")
	elif monster.patrol_path_follow:
		monster.global_position = monster.global_position.move_toward(
			monster.patrol_path_follow.global_position,
			delta * monster.patrol_speed * 2.0
		)
