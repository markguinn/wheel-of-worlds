class_name Player
extends CharacterBody2D

const COYOTE_TIME_MS = 100

@export var holding_hand: Node2D
@export var resting_point: Node2D

## may not use this but the idea was that we could try to animate the motion a little bit
## to line up motion with the feet on the ground. it didn't pan out  very well but i didn't
## rip it out yet. the animation is disabled
@export var walk_multiplier := 1.0

var last_floor_touch: int
var is_holding_prop: Node2D = null
var active_grab_box: GrabBox = null
var start_pos: Vector2

@onready var state_machine: StateMachine = $StateMachine
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Node2D = $Sprite
@onready var shape: CollisionShape2D = $NormalCollision
@onready var shape2: CollisionShape2D = $NormalCollision2
@onready var ground_detector: RayCast2D = $GroundDetector


func _ready() -> void:
	anim_player.play("idle")
	start_pos = position


func reset_after_fall() -> void:
	position = start_pos


func in_coyote_window() -> bool:
	return not is_on_floor() and last_floor_touch + COYOTE_TIME_MS > Time.get_ticks_msec()


func can_jump() -> bool:
	if state_machine.get_active() == "Ragdoll":
		return false
	return is_on_floor() or in_coyote_window()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and state_machine.get_active() != "Ragdoll":
		state_machine.transition_by_name("Ragdoll")
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("jump") and can_jump():
		state_machine.transition_by_name("Jump")
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("interact") and is_holding_prop:
		put_down_prop()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if is_on_floor():
		last_floor_touch = Time.get_ticks_msec()
	if is_holding_prop:
		_update_prop(delta)
	elif velocity != Vector2.ZERO:
		GrabBoxManager.update_active_candidate()


# TODO: trigger a pickup animation?
func pick_up_prop(target_node: Node2D, grab_box: GrabBox) -> bool:
	if ground_detector.is_colliding() and ground_detector.get_collider() == target_node:
		return false
	print("[Player] picking up: ", target_node)
	if is_holding_prop:
		return false
	is_holding_prop = target_node
	active_grab_box = grab_box
	return true


func put_down_prop() -> void:
	if is_holding_prop:
		is_holding_prop.rotation = 0.0 if sprite.scale.x > 0 else PI
		active_grab_box.put_down.emit(self)
		is_holding_prop = null
		active_grab_box = null


func _update_prop(_delta: float) -> void:
	var prop: Node2D = is_holding_prop
	prop.rotation = holding_hand.global_position.angle_to_point(resting_point.global_position) #+ PI / 2
	prop.global_position = holding_hand.global_position # lerp(holding_hand.global_position, resting_point.global_position, 0.5)
