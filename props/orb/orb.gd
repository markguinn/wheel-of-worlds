class_name Orb
extends RigidBody2D


signal persisted_state_changed(node: Node)


var start_pos: Vector2
var last_pos: Vector2
var next_pos: Vector2 = Vector2.INF

@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	start_pos = position


func reset_after_fall() -> void:
	# TODO: make a fun animation
	next_pos = start_pos


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if next_pos != Vector2.INF:
		position = next_pos
		next_pos = Vector2.INF


func get_persisted_state() -> Dictionary:
	return { "position": position }


func restore_persisted_state(data: Dictionary) -> void:
	if "position" in data:
		position = data.get("position")


func _physics_process(_delta: float) -> void:
	if !position.is_equal_approx(last_pos):
		persisted_state_changed.emit(self)
		last_pos = position
