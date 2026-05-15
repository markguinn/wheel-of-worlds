class_name ClimbableTreePlatform
extends StaticBody2D


@export var extra_sway := Vector2.ZERO

@onready var tree: ClimbableTree = $".."
@onready var leaf_particles: GPUParticles2D = %LeafParticles

func _ready() -> void:
	leaf_particles.one_shot = true


func squish(impact_velocity: Vector2, collision_point: Vector2, collision_normal: Vector2) -> Vector2:
	tree.add_impulse(impact_velocity, collision_point, collision_normal)
	leaf_particles.global_position = collision_point
	leaf_particles.restart()
	return Vector2.ZERO
