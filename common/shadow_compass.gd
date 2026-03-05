class_name ShadowCompass
extends CharacterBody2D

@export var probe: ShadowProbe
@export var central_probe: ShadowProbe
@export var probe_radius_px: float = 250.
@export var probes_until_decision: int = 10

## Measurements for light at position: {"pos": Vector2, "light": float}
var probe_measurements: Array[Dictionary] = []

func _physics_process(_delta: float) -> void:
	#if probe_measurements.is_empty():print("Central sample: %s --> %s " %[central_probe.global_position, central_probe.lit_value])
	if probe_measurements.size() <= probes_until_decision:
		#print("Collecting sample %s: %s --> %s " %[probe_measurements.size(), probe.global_position, probe.lit_value])
		# Erase bad samples, udpate good samples
		if is_nan(probe.lit_value) and not probe_measurements.is_empty(): probe_measurements.pop_back()
		elif not is_nan(probe.lit_value) and not probe_measurements.is_empty():
			probe_measurements[-1]["light"] = probe.lit_value
		# Find a random position which isn't occluding light through raycast
		var probe_vector = Vector2(randf() - 0.5, randf() - 0.5).normalized() * 2. * probe_radius_px
		var space_state = get_world_2d().direct_space_state
		var raycast_result = space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
			global_position, global_position + probe_vector
		))
		if "position" in raycast_result:probe.global_position = raycast_result.position
		else: probe.global_position = global_position + probe_vector
		probe_measurements.push_back({"pos": probe.global_position})
	else:
		# First store light level for the last measurement
		probe_measurements[-1]["light"] = probe.lit_value

		# Estimate velocity based on the measured samples
		velocity = get_direction_to_darkness(probe_measurements, central_probe.lit_value, global_position) * 100.
		
		$DebugLine.points[0] = global_position
		$DebugLine.points[1] = global_position + velocity
		move_and_slide()
		probe_measurements.clear()

## Estimate light gradient using weighted sum of sample directions
static func get_direction_to_darkness(measurements: Array[Dictionary], center_light: float, center_pos: Vector2) -> Vector2:
	var gradient = Vector2.ZERO
	for sample in measurements:
		var dir = sample["pos"] - center_pos
		var light_diff = sample["light"] - center_light
		# If sample is brighter than center, gradient points toward it
		gradient += dir.normalized() * light_diff
	# Move OPPOSITE to gradient (toward darkness)
	if gradient.length_squared() < 0.0001:
		return Vector2.ZERO  # Already at local minimum
	return -gradient.normalized()
