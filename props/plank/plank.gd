class_name Plank
extends MoveableRigidBody2D


signal persisted_state_changed(node: Node)


var last_pos: Vector2
var last_rot: float
var start_pos: Vector2
var start_rot: float

var holding_point: Node2D = null

@onready var sprite: Node2D = $Sprite
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var shape2: CollisionShape2D = $CollisionShapeHeld
@onready var handle: StaticBody2D = $Handle
@onready var joint: Joint2D = $Handle/PinJoint2D
@onready var grab_box_l: GrabBox = $Sprite/GrabBoxL
@onready var grab_box_r: GrabBox = $Sprite/GrabBoxR
@onready var sfx_impact: AudioStreamPlayer2D = $ImpactSFX
@onready var vfx_dust: CPUParticles2D = $DustParticles
@onready var wall_detector: RayCast2D = $WallDetector
@onready var floor_detector: RayCast2D = $FloorDetector

func _ready() -> void:
	super._ready()
	# TODO: add checkpoints where this can be reset
	start_pos = global_position
	start_rot = global_rotation
	impact.connect(_on_impact)
	grab_box_l.picked_up.connect(_on_left_pickup)
	grab_box_l.put_down.connect(_on_put_down)
	grab_box_r.picked_up.connect(_on_right_pickup)
	grab_box_r.put_down.connect(_on_put_down)
	shape.disabled = false
	shape2.disabled = true
	joint.node_a = ""
	joint.node_b = ""


func set_checkpoint() -> void:
	start_pos = global_position


func reset_after_fall() -> void:
	# TODO: make a fun animation
	set_next_global_position(start_pos)
	set_next_global_rotation(start_rot)
	set_next_angular_velocity(0.0)
	set_next_linear_velocity(Vector2.ZERO)


func is_uprightish() -> bool:
	Log.debug(self, "is_uprightish", floor_detector.is_colliding())
	return floor_detector.is_colliding()
	#var deg := absf(wrapf(rotation_degrees, -180.0, 180.0))
	#if deg >= 120.0 and deg <= 60.0:
		#return true
	#return false


func _on_impact(pos: Vector2, _vel: Vector2, _obj: Node, _part) -> void:
	sfx_impact.play()
	vfx_dust.global_position = pos
	vfx_dust.emitting = true


func _on_any_pickup(_holding_point: Node2D) -> void:
	holding_point = _holding_point
	global_position = _holding_point.global_position
	handle.reparent(get_parent())
	handle.global_position = holding_point.global_position
	joint.node_b = get_path()
	joint.node_a = handle.get_path()
	set_deferred("freeze", false)
	set_deferred("collision_layer", grab_box_l.target_node_collision_layer)
	shape.disabled = true
	shape2.disabled = false


func _on_left_pickup(_holding_point: Node2D) -> void:
	_on_any_pickup(_holding_point)
	if sprite.position != Vector2.ZERO:
		sprite.position = Vector2.ZERO
		rotation_degrees += 180.0
		sprite.rotation_degrees = 0.0


# we have to do this funky thing because the origin of the
# plank is always what's in the hand of the player.
func _on_right_pickup(_holding_point: Node2D) -> void:
	_on_any_pickup(_holding_point)
	if sprite.position == Vector2.ZERO:
		sprite.position = grab_box_r.position
		rotation_degrees -= 180.0
		sprite.rotation_degrees = 180.0


func _on_put_down() -> void:
	holding_point = null
	joint.node_a = ""
	joint.node_b = ""
	handle.reparent(self)
	shape.disabled = false
	shape2.disabled = true


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
	wall_detector.global_rotation = 0
	if position != last_pos or rotation != last_rot:
		persisted_state_changed.emit(self)
		last_pos = position
		last_rot = rotation
	if holding_point:
		handle.global_position = holding_point.global_position
