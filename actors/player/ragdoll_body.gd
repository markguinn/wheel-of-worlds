class_name PlayerRagdollBody
extends MoveableRigidBody2D


signal impact(collision_point: Vector2, collision_velocity: Vector2, colliding_body: Node, body_part: PlayerRagdollBody)

const DEBOUNCE_IMPACT_MS = 1000

var collision_pos := Vector2.ZERO
var collision_velocity := Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() > 0:
		collision_pos = state.get_contact_local_position(0)
		collision_velocity = state.get_contact_local_velocity_at_position(0)
	super._integrate_forces(state)


func _on_body_entered(body: Node) -> void:
	if body is TileMapLayer or not body.get_collision_layer_value(2):
		if not GameManager.rate_limit(DEBOUNCE_IMPACT_MS, "player_ragdoll_impact"):
			impact.emit.call_deferred(collision_pos, collision_velocity, body, self)
