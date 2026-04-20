extends RigidBody2D

@export var hand_attached_to: Node2D

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	state.linear_velocity = (hand_attached_to.arm_global_position - global_position)
	state.angular_velocity = (hand_attached_to.global_position - global_position).angle() + PI / 2.
