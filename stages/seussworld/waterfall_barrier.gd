class_name WaterfallBarrier
extends Area2D


@export var eject_direction := Vector2.RIGHT
@export var eject_power := 500.0

@onready var splash_particles: CPUParticles2D = $SplashParticles


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is MoveableRigidBody2D:
		body.set_next_linear_velocity(eject_direction * eject_power)
	if body is Player:
		body.velocity = eject_direction * eject_power
		body.state_machine.transition_by_name.call_deferred("Ragdoll")
	splash_particles.global_position.y = body.global_position.y
	splash_particles.restart()
		
