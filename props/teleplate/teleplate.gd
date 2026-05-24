class_name Teleplate
extends MoveableRigidBody2D

signal persisted_state_changed(node: Node)
signal became_ready(plate: Teleplate)
signal became_empty(plate: Teleplate)


@export var linked_plates: Array[Teleplate] = []

var last_pos: Vector2
var last_rot: float
var start_pos: Vector2
var start_rot: float

var active_props: Array[Node2D] = []
var ready_partners: Array[Teleplate] = []

@onready var activator: Activator = $Activator
@onready var grab_box: GrabBox = $GrabBox
@onready var prop_detector: Area2D = $PropDetector
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	start_pos = global_position
	start_rot = global_rotation
	prop_detector.body_entered.connect(_on_prop_entered)
	prop_detector.body_exited.connect(_on_prop_exited)
	activator.activated.connect(_on_activate)
	for p in linked_plates:
		if p != self:
			p.became_ready.connect(_on_partner_ready)
			p.became_empty.connect(_on_partner_empty)


func _on_prop_entered(prop: Node2D) -> void:
	if prop is Teleplate:
		return
	active_props.append(prop)
	Log.debug(self, "prop entered teleplate", prop)
	if active_props.size() == 1:
		Log.debug(self, "teleplate ready")
		became_ready.emit(self)
		grab_box.enabled = false
		animation_player.play("ready")


func _on_prop_exited(prop: Node2D) -> void:
	if not prop in active_props:
		return
	active_props.erase(prop)
	Log.debug(self, "prop exited teleplate", prop)
	if active_props.size() == 0:
		Log.debug(self, "teleplate empty")
		became_empty.emit(self)
	if ready_partners.size() == 0 and active_props.size() == 0:
		grab_box.enabled = true
		animation_player.play("empty")


func _on_partner_ready(plate: Teleplate) -> void:
	ready_partners.append(plate)
	Log.debug(self, "linked plate became ready", plate)
	if ready_partners.size() == 1:
		Log.debug(self, "ready to transport")
		animation_player.play("ready")
		grab_box.enabled = false
		activator.enabled = true


func _on_partner_empty(plate: Teleplate) -> void:
	ready_partners.erase(plate)
	Log.debug(self, "linked plate became empty", plate)
	if ready_partners.size() == 0:
		Log.debug(self, "no longer ready to transport")
		activator.enabled = false
	if ready_partners.size() == 0 and active_props.size() == 0:
		animation_player.play("empty")
		grab_box.enabled = true


func _on_activate(_source: Activator) -> void:
	for plate in linked_plates:
		for node in plate.active_props:
			var relative_pos := node.global_position - plate.global_position
			node.global_position = global_position + relative_pos
			Log.debug(self, "teleported", node, "from", plate, "at offset", relative_pos)


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
