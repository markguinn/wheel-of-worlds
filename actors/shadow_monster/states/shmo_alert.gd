extends ShadowMonsterBaseState


func _entered(_from_state: StateNode) -> void:
	%ScreamSFX.play()
	VFX.shake(VFX.MID, VFX.TREMOR)


func _process(_delta: float) -> void:
	if not monster.target:
		return
	monster.arm.arm_global_position = lerp(monster.arm.arm_global_position, lerp(monster.global_position, monster.target.global_position, 0.25), monster.arm_speed)

	if monster.target_dist < monster.target_attack_distance and GameManager.now_ms() > entered_at + monster.attack_cooldown_ms:
		machine.transition_by_name.call_deferred("Attack")
	elif monster.primary_light and monster.primary_light_dist < monster.lightsource_distance_tolerated:
		machine.transition_by_name.call_deferred("Flee")
	elif monster.target_dist > monster.target_warning_distance:
		machine.transition_by_name.call_deferred("Patrol")
