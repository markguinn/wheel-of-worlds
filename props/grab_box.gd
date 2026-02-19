class_name GrabBox
extends Area2D

signal picked_up
signal put_down


enum State { DISABLED, AVAILABLE, ACTIVE_CANDIDATE, HOLDING }

## Starting state
@export var state := State.AVAILABLE

## The object that's getting grabbed. If not set manually, we'll use the parent node of the grab box
@export var target_node: RigidBody2D

var target_node_collision_layer: int

@onready var label: Label = $Label


##########################################################
# Globally manage props that could be picked up
# but only make the closest one available. 


static var candidates_for_holding: Array[GrabBox] = []


static func add_candidate(obj: GrabBox) -> void:
	if not candidates_for_holding.has(obj):
		candidates_for_holding.append(obj)
		update_active_candidate()


static func remove_candidate(obj: GrabBox) -> void:
	if candidates_for_holding.has(obj):
		if obj.state == State.ACTIVE_CANDIDATE:
			obj._release_active_candidate()
		candidates_for_holding.erase(obj)
		update_active_candidate()


static func update_active_candidate() -> void:
	var player: Player = GameManager.get_player()
	if candidates_for_holding.size() == 0 or player.is_holding_prop:
		return

	var cur_active: GrabBox = null
	var next_active: GrabBox = null
	var min_dist: float = 1_000_000.0 # TODO: use constant when i have internet again
	for obj in candidates_for_holding:
		var my_dist = obj.target_node.global_position.distance_squared_to(player.global_position)
		if my_dist < min_dist:
			next_active = obj
		if obj.state == State.ACTIVE_CANDIDATE:
			cur_active = obj

	if cur_active != next_active:
		if cur_active:
			cur_active._release_active_candidate()
		if next_active:
			next_active._become_active_candidate()


################################################################
# Locally manage when this prop comes in range and when it's picked
# up. Some of this might move to the player (especially the input?)


func _ready() -> void:
	if not target_node:
		target_node = get_parent()
	target_node_collision_layer = target_node.collision_layer
	label.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	put_down.connect(_on_put_down)



func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		add_candidate(self)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		remove_candidate(self)


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
