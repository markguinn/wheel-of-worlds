class_name Player
extends CharacterBody2D

signal did_pick_up(prop: Node2D)
signal did_put_down(prop: Node2D)


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

@onready var dust_particles_l: CPUParticles2D = %DustParticlesL
@onready var dust_particles_r: CPUParticles2D = %DustParticlesR

func _ready() -> void:
	anim_player.play("idle")
	start_pos = position


func reset_after_fall() -> void:
	position = start_pos


func in_coyote_window() -> bool:
	return not is_on_floor() and last_floor_touch + COYOTE_TIME_MS > GameManager.now_ms()


func can_jump() -> bool:
	if state_machine.get_active() == "Ragdoll":
		return false
	return is_on_floor() or in_coyote_window()


func puff_left_dust(dust_scale = 10.0) -> void:
	if is_on_floor():
		dust_particles_l.scale_amount_max = dust_scale
		dust_particles_l.scale_amount_min = dust_scale / 2
		dust_particles_l.emitting = true


func puff_right_dust(dust_scale = 10.0) -> void:
	if is_on_floor():
		dust_particles_r.scale_amount_max = dust_scale
		dust_particles_r.scale_amount_min = dust_scale / 2
		dust_particles_r.emitting = true


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
		last_floor_touch = GameManager.now_ms()
	if is_holding_prop:
		_update_prop(delta)
	elif velocity != Vector2.ZERO:
		GrabBoxManager.update_active_candidate()


# TODO: trigger a pickup animation?
func pick_up_prop(target_node: Node2D, grab_box: GrabBox) -> bool:
	if ground_detector.is_colliding() and ground_detector.get_collider() == target_node:
		return false
	if is_holding_prop:
		return false
	if not is_on_floor():
		return false
	print("[Player] picking up: ", target_node)
	target_node.z_index += 1
	anim_player.play("pickup")
	_finish_pickup(target_node, grab_box)
	return true
	
func _finish_pickup(target_node: Node2D, grab_box: GrabBox) -> void:
	# TODO: should we call a method from the animation
	# TODO: animate the prop
	await get_tree().create_timer(0.25).timeout
	is_holding_prop = target_node
	active_grab_box = grab_box
	await get_tree().create_timer(0.25).timeout
	did_pick_up.emit(target_node)

func put_down_prop() -> void:
	if is_holding_prop:
		is_holding_prop.rotation = 0.0 if sprite.scale.x > 0 else PI
		is_holding_prop.z_index -= 1
		active_grab_box.put_down.emit(self)
		did_put_down.emit(is_holding_prop)
		is_holding_prop = null
		active_grab_box = null


# TODO: I think this is hacky and physically wrong.
# I think it's needed because I'm using a negative scale on 
# the sprite to change direction. We're going to have to change 
# that but I want to get the animations right first.
func _normalize_prop_angle(a: float) -> float:
	var target_rot := a
	while target_rot > 0.0:
		target_rot -= PI
	while target_rot < -PI:
		target_rot += PI
	return target_rot


# FIXME: depending on the angle you come at the plank
# it may look right-ish or totally wrong if you picked
# it up from the other side previously. It should be
# possible to normalize that at pickup or put down.
# TODO: add some easing? it looks suuuuuper fake at linear
func _update_prop(delta: float) -> void:
	var prop: Node2D = is_holding_prop
	var target_rot := holding_hand.global_position.angle_to_point(resting_point.global_position)
	prop.rotation = move_toward(_normalize_prop_angle(prop.rotation), _normalize_prop_angle(target_rot), delta * PI * 2.0)
	prop.global_position = holding_hand.global_position # lerp(holding_hand.global_position, resting_point.global_position, 0.5)
