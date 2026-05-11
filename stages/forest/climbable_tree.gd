class_name ClimbableTree
extends Node2D

@export var squish_speed := 0.2
@export var squished_scale := Vector2(1.05, 0.95)
@export var sway_speed := 4.0
@export var sway_skew := 0.5
@export var sway_decay := 0.8
@export var rotate_amount := 0.5

@onready var platform1: StaticBody2D = $Platform1
@onready var sprite: Sprite2D = $Sprite2D

var squish_amount := 0.0
var target_squish := 0.0
var sway_amount := 0.0
var target_sway := 0.0
var start_sway := 0.0
var sway_tween: Tween


# TODO: periodically add some sway to simulate wind


func add_impulse(impact_velocity: Vector2, collision_point: Vector2, collision_normal: Vector2) -> void:
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

func _start_sway(target: float) -> void:
	if sway_tween:
		sway_tween.stop()
	sway_tween = create_tween()
	sway_tween.set_ease(Tween.EASE_IN_OUT)
	sway_tween.set_trans(Tween.TRANS_SINE)
	sway_tween.tween_property(self, "sway_amount", target, sway_speed)
	Log.debug(self, "start sway", sway_amount, target, sway_speed)
	sway_tween.finished.connect(_on_tween_complete)

func _on_tween_complete() -> void:
	Log.debug(self, "sway complete", sway_amount)
	if absf(sway_amount) >= 0.001:
		_start_sway(-sway_amount * sway_decay)

func _physics_process(delta: float) -> void:
	squish_amount = move_toward(squish_amount, target_squish, delta / squish_speed)
	if is_equal_approx(squish_amount, target_squish):
		target_squish = 0.0
	sprite.scale = Vector2.ONE.lerp(squished_scale, squish_amount)
	
	#sway_amount = rotate_toward(sway_amount, target_sway, 2.0 * absf(target_sway) * delta / sway_speed)
	#if is_equal_approx(sway_amount, target_sway):
		#target_sway = -target_sway * sway_decay
		#if absf(target_sway) < 0.01:
			#target_sway = 0.0
	#Log.debounced(self, "sway", sway_amount, target_sway, smoothstep(-1.0, 1.0, sway_amount), lerpf(-sway_skew, sway_skew, smoothstep(-1.0, 1.0, sway_amount)))
	#var 
	#var val := lerpf(-sway_skew, sway_skew, ease(smoothstep(-1.0, 1.0, sway_amount), -4.4))
	#ease()
	#var val := lerpf(-sway_skew, sway_skew, ease(smoothstep(-1.0, 1.0, sway_amount), -4.4))
	var val := sway_amount # remap(sway_amount, -1.0, 1.0, -sway_amount, sway_amount)
	sprite.skew = val
	sprite.rotation = val * rotate_amount
