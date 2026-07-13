class_name GrabBox
extends Activator

signal picked_up(holding_point: Node2D)
signal put_down

########################################################
## Adding this to an Area2D attached to a RigidBody
## will turn that body into something the player can
## pick up.
########################################################


## The object that's getting grabbed. If not set manually, we'll use the parent node of the grab box
@export var target_node: RigidBody2D
@export var manage_position := true
@export var hold_offset := Vector2.ZERO
@export var hold_degrees := INF

var is_player_holding := false
var target_node_collision_layer: int
var holding_point: Node2D = null


func _ready() -> void:
	super._ready()
	if not target_node:
		target_node = get_parent()
	target_node_collision_layer = target_node.collision_layer
	activated.connect(_on_activated)
	put_down.connect(_on_put_down)
	picked_up.connect(_on_picked_up)


func _on_activated(_source: Activator) -> void:
	if GameManager.get_player().pick_up_prop(target_node, self):
		is_player_holding = true
		label.hide()
		target_node.freeze = true
		target_node.collision_layer = 0


func _on_picked_up(_holding_point: Node2D) -> void:
	Log.debug(self, "was picked up", _holding_point)
	holding_point = _holding_point
	target_node.z_index += 1
	if not is_inf(hold_degrees):
		target_node.rotation_degrees = hold_degrees


func _on_put_down() -> void:
	Log.debug(self, "was put down")
	holding_point = null
	if target_node.z_index > 0:
		target_node.z_index -= 1
	if not is_inf(hold_degrees):
		target_node.global_rotation = 0.0
	target_node.set_deferred("freeze", false)
	target_node.set_deferred("collision_layer", target_node_collision_layer)

	if is_player_holding:
		is_player_holding = false
		Activator.set_active_candidate(self)


func _process(_delta: float) -> void:
	if holding_point and manage_position:
		target_node.global_position = holding_point.global_position + hold_offset
