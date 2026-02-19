class_name GrabBox
extends Area2D

signal picked_up
signal put_down

########################################################
## Adding this to an Area2D attached to a RigidBody
## will turn that body into something the player can
## pick up.
########################################################


enum State { DISABLED, AVAILABLE, ACTIVE_CANDIDATE, HOLDING }

## Starting state
@export var state := State.AVAILABLE

## The object that's getting grabbed. If not set manually, we'll use the parent node of the grab box
@export var target_node: RigidBody2D

var target_node_collision_layer: int

@onready var label: Label = $Label


func _ready() -> void:
	if not target_node:
		target_node = get_parent()
	if not self.get_collision_mask_value(2):
		print("[GrabBox] WARNING: grab box will not detect the player on ", target_node.get_path())
	target_node_collision_layer = target_node.collision_layer
	label.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	put_down.connect(_on_put_down)



func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		GrabBoxManager.add_candidate(self)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		GrabBoxManager.remove_candidate(self)


func _input(event: InputEvent):
	if event.is_action_pressed("interact") and state == State.ACTIVE_CANDIDATE:
		_start_holding()
		get_viewport().set_input_as_handled()


func _become_active_candidate() -> void:
	label.show()
	state = State.ACTIVE_CANDIDATE


func _release_active_candidate() -> void:
	label.hide()
	state = State.AVAILABLE


func _start_holding() -> void:
	if GameManager.get_player().pick_up_prop(target_node, self):
		state = State.HOLDING
		label.hide()
		picked_up.emit()
		target_node.freeze = true
		#is_holding.collision_mask ^= target_node_collision_layer
		target_node.collision_layer = 0


func _on_put_down(holder: Player) -> void:
	_become_active_candidate()
	target_node.freeze = false
	target_node.collision_layer = target_node_collision_layer
	#holder.collision_mask |= target_node_collision_layer
	#print("putting down: ", target_node)
