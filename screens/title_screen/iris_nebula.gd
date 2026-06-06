@tool
extends Sprite2D

@export var skew_min := -0.1
@export var skew_max := 0.1
@export var skew_speed := 1.0
@export var alpha_min := 0.2
@export var alpha_max := 0.5
@export var alpha_speed := 1.0
@export var rotation_speed := 1.0
@export var speed_factor := 1.0

var target_rot := 0.0
var target_skew := 0.0
var target_alpha := 0.5


func _process(delta: float) -> void:
	if is_equal_approx(rotation, target_rot):
		target_rot = randf_range(0.0, PI * 2.0)
	if is_equal_approx(skew, target_skew):
		target_skew = randf_range(skew_min, skew_max)
	if is_equal_approx(modulate.a, target_alpha):
		target_alpha = randf_range(alpha_min, alpha_max)
	rotation = move_toward(rotation, target_rot, delta * speed_factor * skew_speed)
	skew = move_toward(skew, target_skew, delta * speed_factor * skew_speed)
	modulate.a = move_toward(modulate.a, target_alpha, delta * speed_factor * alpha_speed)
