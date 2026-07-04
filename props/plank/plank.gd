class_name Plank
extends MoveableRigidBody2D


signal persisted_state_changed(node: Node)


var last_pos: Vector2
var last_rot: float
var start_pos: Vector2
var start_rot: float

var holding_point: Node2D = null
var resting_point: Node2D = null

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
@onready var glow: Node = $Sprite/Glow


func _ready() -> void:
	super._ready()
	start_pos = global_position
	start_rot = global_rotation
	glow.hide()
	impact.connect(_on_impact)
	grab_box_l.picked_up.connect(_on_left_pickup)
	grab_box_l.put_down.connect(_on_put_down)
	grab_box_l.become_candidate.connect(_on_become_active_candidate)
	grab_box_l.resign_candidate.connect(_on_resign_active_candidate)
	grab_box_r.picked_up.connect(_on_right_pickup)
	grab_box_r.put_down.connect(_on_put_down)
	grab_box_r.become_candidate.connect(_on_become_active_candidate)
	grab_box_r.resign_candidate.connect(_on_resign_active_candidate)
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
	return Flags.plank_struggle_mode and floor_detector.is_colliding()


func before_put_down() -> void:
	if not Flags.plank_struggle_mode:
		var target_rot := 0.0 if GameManager.get_player().sprite.scale.x > 0.0 else -PI
		Log.debug(self, "target_rot", target_rot)
		set_next_global_rotation(target_rot)


func _on_impact(pos: Vector2, _vel: Vector2, _obj: Node, _part) -> void:
	sfx_impact.play()
	vfx_dust.global_position = pos
	vfx_dust.emitting = true


func _on_any_pickup(_holding_point: Node2D) -> void:
	holding_point = _holding_point
	global_position = _holding_point.global_position
	if Flags.plank_struggle_mode:
		handle.reparent(get_parent())
		handle.global_position = holding_point.global_position
		joint.node_b = get_path()
		joint.node_a = handle.get_path()
		set_deferred("freeze", false)
		set_deferred("collision_layer", grab_box_l.target_node_collision_layer)
		shape.disabled = true
		shape2.disabled = false
	else:
		# this is an awkward, leaky abstraction but the alternatives are hacky too and don't improve anything
		resting_point = GameManager.get_player().resting_point


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
		if Flags.plank_struggle_mode:
			handle.global_position = holding_point.global_position
		else:
			var ang := holding_point.global_position.angle_to_point(resting_point.global_position)
			set_next_global_position(holding_point.global_position)
			set_next_global_rotation(ang)


func _on_become_active_candidate(_prev: Activator) -> void:
	glow.show()


func _on_resign_active_candidate(_next: Activator) -> void:
	glow.hide()
