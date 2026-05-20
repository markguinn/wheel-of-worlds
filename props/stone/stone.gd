class_name Stone
extends MoveableRigidBody2D

signal persisted_state_changed(node: Node)


## If set, the stone can't be picked up or pushed
@export var fixed := false

var last_pos: Vector2
var last_rot: float
var start_pos: Vector2
var start_rot: float


func _ready() -> void:
	start_pos = global_position
	start_rot = global_rotation
	if fixed:
		$GrabBox.enabled = false
		freeze = true


func set_checkpoint() -> void:
	start_pos = position


func reset_after_fall() -> void:
	# TODO: make a fun animation
	set_next_global_position(start_pos)
	set_next_global_rotation(start_rot)
	set_next_angular_velocity(0.0)
	set_next_linear_velocity(Vector2.ZERO)


func get_persisted_state() -> Dictionary:
	return { 
		"position": global_position,
		"rotation": global_rotation,
	}


func restore_persisted_state(data: Dictionary) -> void:
	if "position" in data:
		global_position = data.get("position")
	if "rotation" in data:
		global_rotation = data.get("rotation")


func _physics_process(_delta: float) -> void:
	if global_position != last_pos or global_rotation != last_rot:
		persisted_state_changed.emit(self)
		last_pos = global_position
		last_rot = global_rotation
