class_name Stone
extends RigidBody2D

signal persisted_state_changed(node: Node)

var last_pos: Vector2
var last_rot: float


func get_persisted_state() -> Dictionary:
	return { 
		"position": position,
		"rotation": rotation,
	}


func restore_persisted_state(data: Dictionary) -> void:
	if "position" in data:
		position = data.get("position")
	if "rotation" in data:
		rotation = data.get("rotation")


func _physics_process(_delta: float) -> void:
	if position != last_pos or rotation != last_rot:
		persisted_state_changed.emit(self)
		last_pos = position
		last_rot = rotation
