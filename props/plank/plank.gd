class_name Plank
extends MoveableRigidBody2D


signal persisted_state_changed(node: Node)


var last_pos: Vector2
var last_rot: float
var start_pos: Vector2
var start_rot: float

@onready var sprite: Node2D = $Sprite
@onready var grab_box_l: GrabBox = $Sprite/GrabBoxL
@onready var grab_box_r: GrabBox = $Sprite/GrabBoxR
@onready var sfx_impact: AudioStreamPlayer2D = $ImpactSFX
@onready var vfx_dust: CPUParticles2D = $DustParticles


func _ready() -> void:
	super._ready()
	# TODO: add checkpoints where this can be reset
	start_pos = global_position
	start_rot = global_rotation
	impact.connect(_on_impact)
	grab_box_l.picked_up.connect(_on_left_pickup)
	grab_box_r.picked_up.connect(_on_right_pickup)


func reset_after_fall() -> void:
	# TODO: make a fun animation
	set_next_global_position(start_pos)
	set_next_global_rotation(start_rot)
	set_next_angular_velocity(0.0)
	set_next_linear_velocity(Vector2.ZERO)


func _on_impact(pos: Vector2, vel: Vector2, obj: Node, _part) -> void:
	sfx_impact.play()
	vfx_dust.global_position = pos
	vfx_dust.emitting = true


func _on_left_pickup() -> void:
	global_position = grab_box_l.global_position
	if sprite.position != Vector2.ZERO:
		sprite.position = Vector2.ZERO
		rotation_degrees += 180.0
		sprite.rotation_degrees = 0.0


# we have to do this funky thing because the origin of the
# plank is always what's in the hand of the player.
func _on_right_pickup() -> void:
	global_position = grab_box_r.global_position
	if sprite.position == Vector2.ZERO:
		sprite.position = grab_box_r.position
		rotation_degrees -= 180.0
		sprite.rotation_degrees = 180.0


# TODO: this can be generalized, maybe to a PersistenceManager node or something


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
