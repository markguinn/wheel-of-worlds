class_name GrabBox
extends Activator

signal picked_up
signal put_down

########################################################
## Adding this to an Area2D attached to a RigidBody
## will turn that body into something the player can
## pick up.
########################################################


## The object that's getting grabbed. If not set manually, we'll use the parent node of the grab box
@export var target_node: RigidBody2D

var is_holding := false
var target_node_collision_layer: int


func _ready() -> void:
	super._ready()
	if not target_node:
		target_node = get_parent()
	target_node_collision_layer = target_node.collision_layer
	activated.connect(_start_holding)
	put_down.connect(_on_put_down)


func _start_holding(_source: Activator) -> void:
	if GameManager.get_player().pick_up_prop(target_node, self):
		is_holding = true
		label.hide()
		picked_up.emit()
		target_node.freeze = true
		#is_holding.collision_mask ^= target_node_collision_layer
		target_node.collision_layer = 0


func _on_put_down(_holder: Player) -> void:
	is_holding = false
	target_node.freeze = false
	target_node.collision_layer = target_node_collision_layer
	Activator.set_active_candidate(self)
	#holder.collision_mask |= target_node_collision_layer
	#print("putting down: ", target_node)
