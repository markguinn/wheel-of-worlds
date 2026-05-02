extends ColorRect

@export_range(0., 1.) var phase_speed: float = 0.455
@export_range(0., 1.) var phase_noise_offset_change_edge_threshold: float = 0.15
@export_range(0., 1.) var phase_noise_offset_radius: float = 0.1
@export_range(0., 10.) var phase_angle_rotation_speed_inverse: float = 2.352

var phase_direction: float = 1.
var phase_angle_direction: float = 1.
var current_phase: float = 0.
var phase_angle: float = 0.
var current_angle_phase_direction_delta: float = 0.
func _process(delta: float) -> void:
	if 0 > current_phase or 1. < current_phase:
		phase_direction *= -1.
		if 0.5 < randf(): phase_angle_direction = -1.
		else: phase_angle_direction = 1.
	var phase_distance_from_edge: float = abs(min(current_phase, 1. - current_phase))
	current_phase += (
		phase_direction * delta * phase_speed
		* max(phase_distance_from_edge, phase_speed)
	)
	get_material().set_shader_parameter("noise_middle_range", current_phase)
	var phase_angle_speed = pow(delta * phase_speed, phase_angle_rotation_speed_inverse)
	if phase_distance_from_edge < phase_noise_offset_change_edge_threshold: # It's less obvious to change the texture offset at this point
		current_angle_phase_direction_delta += phase_angle_direction
	else: current_angle_phase_direction_delta = max(0., current_angle_phase_direction_delta - phase_angle_speed)
	if 0. < current_angle_phase_direction_delta:
		phase_angle += current_angle_phase_direction_delta * phase_angle_speed
		get_material().set_shader_parameter("noise_offset", Vector2(cos(phase_angle), sin(phase_angle)) * phase_noise_offset_radius)
