extends CanvasGroup

@export var min_dist := 200.0
@export var max_dist := 2000.0
@export var dist_scale := 1.0

@onready var sun_point: Marker2D = %SunPoint

func _process(_delta: float) -> void:
	var sm: ShaderMaterial = material
	var player := GameManager.get_player()
	if not player:
		return
	var dir := sun_point.global_position.direction_to(player.global_position)
	var dist := absf(sun_point.global_position.x - player.global_position.x)
	var strength := clampf(smoothstep(max_dist, min_dist, dist * dist_scale), 0.0, 1.0)
	if not VFX.slow_shaders_enabled:
		strength = 0.0
	sm.set_shader_parameter("ray_direction", -dir)
	sm.set_shader_parameter("output_multiplier", strength)
