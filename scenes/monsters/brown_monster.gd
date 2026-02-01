class_name BrownMonster
extends RigidBody2D

@export var path_follow: PathFollow2D
@export var jump_velocity: Vector2 = Vector2(0, -500.0)


@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var forecast_particles: CPUParticles2D = $CPUParticles2D
@onready var forecast_timer: Timer = $ForecastTimer
@onready var emerge_timer: Timer = $EmergeTimer
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	if not path_follow:
		path_follow = get_parent()
	#if emerge_timer.
	#emerge_timer.start()
	emerge_timer.connect("timeout", _on_timer_timeout)
	forecast_timer.connect("timeout", _stop_forecasting)
	show()
	_disable()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		emerge()

func emerge():
	print("emerge")
	path_follow.progress_ratio = randf_range(0.0, 1.0)
	set_deferred("position", Vector2.ZERO)
	set_deferred("linear_velocity", Vector2.ZERO)
	set_deferred("gravity_scale", 0.0)
	set_deferred("rotation_degrees", -180.0)
	await get_tree().physics_frame
	#global_position = path_follow.global_position
	#global_rotation = path_follow.global_rotation + PI
	#position = path_follow.position
	#rotation_degrees = path_follow.rotation_degrees - 180
	#linear_velocity = Vector2.ZERO
	#freeze = true
	#rotation = 0
	#forecast_particles.rotation = 0
	_start_forecasting()
	await forecast_timer.timeout
	_enable()
	_start_jump()
	

func _process(delta: float) -> void:
	#position = Vector2.ZERO
	#rotation_degrees = -180
	
	#rotation = -PI
	#print('pos:',position,',rot:',rotation_degrees)
	pass


func _start_forecasting() -> void:
	print("start forecasting")
	#forecast_particles.rotation = 0
	#forecast_particles.direction = _get_rotated_jump_vel().normalized()
	#print("--dir:", forecast_particles.direction)
	forecast_particles.emitting = true
	forecast_timer.start()


func _stop_forecasting() -> void:
	print('stop forecasting')
	forecast_particles.emitting = false

func _get_rotated_jump_vel() -> Vector2:
	return jump_velocity.rotated(global_rotation)

func _start_jump():
	print('-------pos:', position, ' -> ', global_position, ' <- ', path_follow.position)	
	print('pr:',path_follow.progress_ratio)	
	print('rot:',rotation_degrees)
	print('grot:',global_rotation_degrees)
	print('jv:',jump_velocity)
	set_deferred("linear_velocity", _get_rotated_jump_vel())
	set_deferred("gravity_scale", 1.0)

func _disable():
	print("disable")
	sprite.hide()
	shape.disabled = true
	#freeze = true
	set_deferred("gravity_scale", 0.0)
	set_deferred("linear_velocity", Vector2.ZERO)
	set_deferred("position", Vector2.ZERO)
	forecast_particles.emitting = false


func _enable():
	print("enable")
	sprite.show()
	shape.disabled = false


func _on_timer_timeout():
	print("timer")
	call_deferred("emerge")


func _on_exited_screen() -> void:
	print("exited screen")
	#pass
	_disable()
