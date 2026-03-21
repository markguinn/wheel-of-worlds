class_name MoveableRigidBody2D
extends RigidBody2D

var next_global_position := Vector2.INF
var next_global_rotation := INF
var next_linear_velocity := Vector2.INF
var next_angular_velocity := INF


func set_next_global_position(v: Vector2) -> void:
	global_position = v
	next_global_position = v

func set_next_linear_velocity(v: Vector2) -> void:
	linear_velocity = v
	next_linear_velocity = v

func set_next_global_rotation(v: float) -> void:
	global_rotation = v
	next_global_rotation = v
	
func set_next_angular_velocity(v: float) -> void:
	angular_velocity = v
	next_angular_velocity = v


func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	if next_global_position != Vector2.INF:
		global_position = next_global_position
		next_global_position = Vector2.INF
	if next_linear_velocity != Vector2.INF:
		linear_velocity = next_linear_velocity
		next_linear_velocity = Vector2.INF
	if not is_inf(next_global_rotation):
		global_rotation = next_global_rotation
		next_global_rotation = INF
	if not is_inf(next_angular_velocity):
		angular_velocity = next_angular_velocity
		next_angular_velocity = INF
