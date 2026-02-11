class_name GrabBox
extends Area2D

signal picked_up
signal put_down


## The object that's getting grabbed. If not set manually, we'll use the parent node of the grab box
@export var target_node: RigidBody2D


var can_hold: Player = null
var is_holding: Player = null
var label_offset: Vector2
var starting_layer_mask: int


@onready var label: Label = $Label


func _ready() -> void:
	if not target_node:
		target_node = get_parent()
	starting_layer_mask = target_node.collision_layer
	label_offset = label.position
	label.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	put_down.connect(_on_put_down)



func _process(delta: float) -> void:
	if label.visible:
		label.rotation = -global_rotation
		label.global_position = global_position + label_offset


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_holding:
		label.show()
		can_hold = body


func _on_body_exited(body: Node2D) -> void:
	if body is Player and not is_holding:
		label.hide()
		can_hold = null


func _input(event: InputEvent):
	if event.is_action_pressed("interact") and can_hold:
		_start_holding()
		get_viewport().set_input_as_handled()


func _start_holding() -> void:
	if can_hold and can_hold.pick_up_prop(target_node, self):
		is_holding = can_hold
		can_hold = null
		label.hide()
		picked_up.emit()
		target_node.freeze = true
		is_holding.collision_mask ^= starting_layer_mask
		#target_node.collision_layer = 0


func _on_put_down(holder: Player) -> void:
	can_hold = holder
	is_holding = null
	label.show()
	target_node.freeze = false
	#target_node.collision_layer = starting_layer_mask
	holder.collision_mask |= starting_layer_mask
	print("putting down: ", target_node)
