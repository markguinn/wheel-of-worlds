extends ShadowMonsterBaseState


func _entered(_from_state: StateNode) -> void:
	%ScreamSFX.play()
	VFX.shake(VFX.MID, VFX.TREMOR)


func _process(_delta: float) -> void:
	if not monster.target:
		return

	var arm_dir = monster.global_position.direction_to(monster.target.global_position)
	monster.arm.arm_global_position = monster.global_position + arm_dir * monster.target_attack_distance * 0.25

	if monster.target_dist < monster.target_attack_distance and GameManager.now_ms() > entered_at + monster.attack_cooldown_ms:
		machine.transition_by_name.call_deferred("Attack")
	elif monster.primary_light and monster.primary_light_dist < monster.lightsource_distance_tolerated:
		machine.transition_by_name.call_deferred("Flee")
	elif monster.target_dist > monster.target_warning_distance:
		machine.transition_by_name.call_deferred("Patrol")
