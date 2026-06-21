extends ShadowMonsterBaseState


const SPASM_COOLDOWN_MS = 1000

func _before_exit(_to_state: StateNode) -> void:
	monster.scale = Vector2.ONE

func _process(delta: float) -> void:
	if monster.target_dist < monster.target_attack_distance and GameManager.now_ms() > entered_at + monster.attack_cooldown_ms:
		machine.transition_by_name.call_deferred("Attack")
	elif (not monster.primary_light or monster.primary_light_dist > monster.lightsource_distance_tolerated) and GameManager.now_ms() > entered_at + 500:
		machine.transition_by_name.call_deferred("Patrol")
	elif not monster.colliding_walls.is_empty():
		monster.global_position += monster.colliding_direction * monster.hover_speed * delta
	elif monster.primary_light:
		var dir = monster.primary_light.global_position.direction_to(monster.global_position)
		monster.global_position += dir * monster.hover_speed * delta

		var spasm_cooldown = remap(
			monster.primary_light_dist, 
			0.0, monster.lightsource_distance_tolerated,
			200.0, 500.0
		)
		var magnitude = remap(
			monster.primary_light_dist, 
			0.0, monster.lightsource_distance_tolerated,
			100.0, 50.0,
		)
		var pulse_size = remap(
			monster.primary_light_dist, 
			0.0, monster.lightsource_distance_tolerated,
			0.2, 1.0,
		)
		if GameManager.now_ms() > entered_at + spasm_cooldown:
			entered_at = GameManager.now_ms()
			if randf() < 0.2:
				%ScreamSFX.play()
			var arm_dir = Vector2.from_angle(randf_range(0, PI * 2.0))
			monster.arm.arm_global_position = monster.global_position + arm_dir * magnitude
			monster.scale = Vector2.ONE * pulse_size
		else:
			monster.arm.arm_global_position = monster.arm.arm_global_position.move_toward(monster.global_position, delta * magnitude * 2.0)
			monster.scale = monster.scale.move_toward(Vector2.ONE, delta)
