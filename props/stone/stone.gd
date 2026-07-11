class_name Stone
extends MoveableRigidBody2D

signal persisted_state_changed(node: Node)


## If set, the stone can't be picked up or pushed
@export var fixed := false

var last_pos: Vector2
var last_rot: float
var start_pos: Vector2
var start_rot: float

@onready var sfx_impact: AudioStreamPlayer2D #= $DropSound
@onready var vfx_dust: CPUParticles2D #= $DustParticles
@onready var glow: Node = $Glow
@onready var grab_box: GrabBox = $GrabBox

func _ready() -> void:
	super._ready()
	impact.connect(_on_impact)
	var marker_idx := get_children().find_custom(func(n): return n is Marker2D)
	if marker_idx > -1:
		var marker: Marker2D = get_child(marker_idx)
		start_pos = marker.global_position
		start_rot = marker.global_rotation
	else:
		start_pos = global_position
		start_rot = global_rotation
	if fixed:
		$GrabBox.enabled = false
		freeze = true
	sfx_impact = get_node_or_null("DropSound")
	vfx_dust = get_node_or_null("DustParticles")
	glow.hide()
	grab_box.become_candidate.connect(_on_become_active_candidate)
	grab_box.resign_candidate.connect(_on_resign_active_candidate)


func _on_impact(pos: Vector2, vel: Vector2, _obj: Node, _part) -> void:
	if sfx_impact:
		var vol = clampf(inverse_lerp(300, 2000, vel.length()), 0.0, 1.0)
		sfx_impact.volume_linear = vol
		sfx_impact.play()
	if vfx_dust:
		vfx_dust.global_position = pos
		vfx_dust.emitting = true


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
	if "position" in data and data["position"] is Vector2:
		set_next_global_position(data["position"])
	if "rotation" in data:
		global_rotation = data.get("rotation")


func _physics_process(_delta: float) -> void:
	if global_position != last_pos or global_rotation != last_rot:
		persisted_state_changed.emit(self)
		last_pos = global_position
		last_rot = global_rotation


func _on_become_active_candidate(_prev: Activator) -> void:
	glow.show()


func _on_resign_active_candidate(_next: Activator) -> void:
	glow.hide()
