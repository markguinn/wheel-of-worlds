class_name Player
extends CharacterBody2D

signal did_pick_up(prop: Node2D, holding_point: Node2D)
signal did_put_down(prop: Node2D)

const AVG_WINDOW_MS = 50.0 # NOTE: this isn't _really_ milliseconds.
const COYOTE_TIME_MS = 100

@export var holding_hand: Node2D
@export var resting_point: Node2D

@export var tough_mode := false
@export var jump_multiplier := 1.0
@export var speed_multiplier := 1.0

var last_floor_touch: int
var is_holding_prop: Node2D = null
var active_grab_box: GrabBox = null
var start_pos: Vector2
var avg_recent_velocity := Vector2.ZERO


@onready var state_machine: StateMachine = $StateMachine
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Node2D = $Sprite
@onready var shape: CollisionShape2D = $NormalCollision
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
	if event.is_action_pressed("jump") and can_jump():
		state_machine.transition_by_name("Jump")
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("interact"):
		if is_holding_prop:
			put_down_prop.call_deferred()
			get_viewport().set_input_as_handled()
		elif Activator.active_candidate:
			Activator.active_candidate.activated.emit.call_deferred(Activator.active_candidate)
		elif state_machine.get_active() != "Ragdoll":
			state_machine.transition_by_name.call_deferred("Ragdoll")
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_update_avg_recent_velocity(delta)
	if is_on_floor():
		last_floor_touch = GameManager.now_ms()
	if is_holding_prop:
		_update_prop(delta)
	elif velocity != Vector2.ZERO:
		Activator.update_active_candidate()
		
		
func _update_avg_recent_velocity(delta: float) -> void:
	var delta_ms := delta * 1000.0
	var idelta_ms := AVG_WINDOW_MS - delta_ms
	avg_recent_velocity.x = (avg_recent_velocity.x * idelta_ms + velocity.x * delta_ms) / AVG_WINDOW_MS
	avg_recent_velocity.y = (avg_recent_velocity.y * idelta_ms + velocity.y * delta_ms) / AVG_WINDOW_MS


func pick_up_prop(target_node: Node2D, grab_box: GrabBox) -> bool:
	if ground_detector.is_colliding() and ground_detector.get_collider() == target_node:
		return false
	if is_holding_prop:
		return false
	if not is_on_floor():
		return false
	if GameManager.rate_limit(500, "player_pick_up"):
		return false
	Log.info(self, "picking up:", target_node.name, grab_box.name)
	if grab_box.global_position.y > holding_hand.global_position.y:
		anim_player.play("pickup")
	else:
		# TODO: should we have an animation where he reaches his arms up?
		finish_pickup.call_deferred()
	active_grab_box = grab_box
	return true


# this is called by the animation player at the point when it makes sense in the animation
func finish_pickup() -> void:
	Log.debug(self, "finished pick up")
	is_holding_prop = active_grab_box.target_node
	active_grab_box.picked_up.emit(holding_hand)
	did_pick_up.emit(active_grab_box.target_node)
	Activator.clear_candidates()


func put_down_prop() -> void:
	if is_holding_prop:
		Log.info(self, "putting down:", is_holding_prop.name, active_grab_box.name)
		#is_holding_prop.rotation_degrees = 0.0 if sprite.scale.x > 0 else 180.0
		#is_holding_prop.z_index -= 1
		active_grab_box.put_down.emit()
		did_put_down.emit(active_grab_box.target_node)
		is_holding_prop = null
		active_grab_box = null


# TODO: I think this is hacky and physically wrong.
# I think it's needed because I'm using a negative scale on 
# the sprite to change direction. We're going to have to change 
# that but I want to get the animations right first.
func _normalize_prop_angle(a: float) -> float:
	var target_rot := a
	while target_rot > 90.0:
		target_rot -= 360.0
	while target_rot < -270.0:
		target_rot += 360.0
	return target_rot


# FIXME: depending on the angle you come at the plank
# it may look right-ish or totally wrong if you picked
# it up from the other side previously. It should be
# possible to normalize that at pickup or put down.
# TODO: add some easing? it looks suuuuuper fake at linear
func _update_prop(_delta: float) -> void:
	pass
	#var prop: Node2D = is_holding_prop
	#var target_deg := _normalize_prop_angle(rad_to_deg(holding_hand.global_position.angle_to_point(resting_point.global_position)))
	#prop.rotation_degrees = _normalize_prop_angle(prop.rotation_degrees)
	#prop.rotation_degrees = move_toward(prop.rotation_degrees, target_deg, delta * 360.0)
	#prop.global_position = holding_hand.global_position # lerp(holding_hand.global_position, resting_point.global_position, 0.5)
