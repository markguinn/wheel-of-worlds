class_name ClimbableTreePlatform
extends StaticBody2D


@export var extra_sway := Vector2.ZERO

@onready var tree: ClimbableTree = $".."


func squish(impact_velocity: Vector2, collision_point: Vector2, collision_normal: Vector2) -> Vector2:
	tree.add_impulse(impact_velocity, collision_point, collision_normal)
	return Vector2.ZERO
