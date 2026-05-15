class_name ClimbableTree
extends Node2D

@export var squish_speed := 0.2
@export var squished_scale := Vector2(1.05, 0.95)
@export var sway_speed := 4.0
@export var sway_skew := 0.5
@export var sway_decay := 0.8
@export var rotate_amount := 0.5

@export var wind_sway_min := 4.0
@export var wind_sway_max := 8.0
@export var wind_sway_mod := 0.4

@onready var platform1: StaticBody2D = $Platform1
@onready var sprite: Sprite2D = $Sprite2D

var squish_amount := 0.0
var target_squish := 0.0
var sway_amount := 0.0
var sway_tween: Tween


func _ready() -> void:
	_set_next_wind_sway()


func add_impulse(impact_velocity: Vector2, collision_point: Vector2, _collision_normal: Vector2) -> void:
	if impact_velocity.y < 100.0:
		Log.debug(self, "not adding impulse", impact_velocity)
		return
	var impact_amount := smoothstep(100.0, 1000.0, impact_velocity.y)
	Log.debug(self, "add impulse", impact_velocity, impact_amount)
	target_squish = squish_amount + impact_amount
	var half_width := sprite.get_rect().size.x / 2.0
	var impact_sway := remap(collision_point.x - sprite.global_position.x, -half_width, half_width, -sway_skew, sway_skew) * impact_amount
	_start_sway(impact_sway)
	Log.debug(self, "add impulse", impact_velocity, half_width, impact_sway, collision_point.x - sprite.global_position.x)


func _set_next_wind_sway() -> void:
	var next_sway_seconds := randf_range(wind_sway_min, wind_sway_max)
	var t := get_tree().create_timer(next_sway_seconds)
	t.timeout.connect(_on_wind_sway)


func _on_wind_sway() -> void:
	if not sway_tween or not sway_tween.is_running():
		var next_sway_amount := randf_range(-sway_skew * wind_sway_mod, sway_skew * wind_sway_mod)
		Log.debug(self, "wind sway", next_sway_amount)
		_start_sway(next_sway_amount)
	else:
		Log.debug(self, "skipping wind sway because we were already in the middle of one")


func _start_sway(target: float) -> void:
	if sway_tween:
		sway_tween.stop()
	sway_tween = create_tween()
	sway_tween.set_ease(Tween.EASE_IN_OUT)
	sway_tween.set_trans(Tween.TRANS_QUAD)
	sway_tween.tween_property(self, "sway_amount", target, sway_speed)
	Log.debug(self, "start sway", sway_amount, target, sway_speed)
	sway_tween.finished.connect(_on_tween_complete)


func _on_tween_complete() -> void:
	Log.debug(self, "sway complete", sway_amount)
	if absf(sway_amount) >= 0.005:
		_start_sway(-sway_amount * sway_decay)
	else:
		_set_next_wind_sway()


func _physics_process(delta: float) -> void:
	squish_amount = move_toward(squish_amount, target_squish, delta / squish_speed)
	if is_equal_approx(squish_amount, target_squish):
		target_squish = 0.0
	sprite.scale = Vector2.ONE.lerp(squished_scale, squish_amount)
	
	sprite.skew = sway_amount
	sprite.rotation = sway_amount * rotate_amount
