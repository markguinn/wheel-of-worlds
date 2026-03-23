class_name MoveableRigidBody2D
extends RigidBody2D

signal impact(collision_point: Vector2, collision_velocity: Vector2, colliding_body: Node, body_part: PlayerRagdollBody)

@export var debounce_impact_scope := ""
@export var debounce_impact_ms := 1000

var next_global_position := Vector2.INF
var next_global_rotation := INF
var next_linear_velocity := Vector2.INF
var next_angular_velocity := INF

var collision_pos := Vector2.ZERO
var collision_velocity := Vector2.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if not debounce_impact_scope:
		debounce_impact_scope = name


func _on_body_entered(body: Node) -> void:
	if body is TileMapLayer or not body.get_collision_layer_value(2):
		if not GameManager.rate_limit(debounce_impact_ms, debounce_impact_scope + "_impact"):
			impact.emit.call_deferred(collision_pos, collision_velocity, body, self)


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


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		collision_pos = state.get_contact_local_position(0)
		collision_velocity = state.get_contact_local_velocity_at_position(0)
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
