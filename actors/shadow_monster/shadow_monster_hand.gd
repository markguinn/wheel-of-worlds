extends RigidBody2D

@export var hand_attached_to: Node2D
@export var arm_momentum_ratio: float = 7.5
@export var max_length: float = 1000.0

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if hand_attached_to.arm_global_position == Vector2.INF:
		return
	state.linear_velocity = (hand_attached_to.arm_global_position - global_position) * arm_momentum_ratio
	state.angular_velocity = (hand_attached_to.global_position - global_position).angle() + PI / 2.
	
	# this is a hack to get around cases where the fingers get stuck
	if hand_attached_to.arm_global_position.distance_to(global_position) > max_length:
		Log.warn(self, "monster hand got stuck!", get_path(), hand_attached_to.global_position)
		global_position = hand_attached_to.global_position
		%TopFinger.set_next_global_position(global_position + Vector2(25, -18))
		%MiddleFinger.set_next_global_position(global_position + Vector2(34, 0))
		%BottomFinger.set_next_global_position(global_position + Vector2(20, 16))
