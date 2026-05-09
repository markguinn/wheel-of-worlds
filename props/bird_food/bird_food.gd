class_name BirdFood
extends MoveableRigidBody2D

signal persisted_state_changed(node: Node)
signal collected


var last_pos: Vector2
var last_rot: float

@onready var grab_box: GrabBox = $GrabBox


func _ready() -> void:
	grab_box.picked_up.connect(_on_picked_up)


func _on_picked_up(_holding_point: Node2D) -> void:
	collected.emit()


func reset_after_fall() -> void:
	queue_free()


func get_persisted_state() -> Dictionary:
	return { 
		"position": global_position,
		"rotation": global_rotation,
	}


func restore_persisted_state(data: Dictionary) -> void:
	if "position" in data:
		set_next_global_position(data.get("position"))
	if "rotation" in data:
		set_next_global_rotation(data.get("rotation"))


func _physics_process(_delta: float) -> void:
	if global_position != last_pos or global_rotation != last_rot:
		persisted_state_changed.emit(self)
		last_pos = global_position
		last_rot = global_rotation
