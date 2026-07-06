class_name Player
extends CharacterBody2D

signal did_pick_up(prop: Node2D, holding_point: Node2D)
signal did_put_down(prop: Node2D)

enum EmotionalState {
	NEUTRAL,
	SCARED,
	STUNNED,
}

const AVG_WINDOW_MS = 50.0 # NOTE: this isn't _really_ milliseconds.
const COYOTE_TIME_MS = 100

@export var holding_hand: Node2D
@export var resting_point: Node2D

@export var has_music_box := true
@export var tough_mode := false
@export var jump_multiplier := 1.0
@export var speed_multiplier := 1.0
@export var emotional_state := EmotionalState.NEUTRAL
@export var ignore_inputs := false
@export var perma_ragdoll := false
@export var set_horizontal_camera_offset := true


var last_floor_touch: int
var is_holding_prop: Node2D = null
var active_grab_box: GrabBox = null
var start_pos: Vector2

@onready var history_buffer: PositionHistoryBuffer = $PositionHistoryBuffer
@onready var state_machine: StateMachine = $StateMachine
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Node2D = $Sprite
@onready var skeleton: Skeleton2D = $Sprite/Skeleton2D
@onready var shape: CollisionShape2D = $NormalCollision
@onready var ground_detector: RayCast2D = $Sprite/Rays/GroundDetector

@onready var dust_particles_l: CPUParticles2D = %DustParticlesL
@onready var dust_particles_r: CPUParticles2D = %DustParticlesR


func _ready() -> void:
	anim_player.play("idle")
	start_pos = position
	skeleton.get_modification_stack().enabled = true
	$AudioListener2D.make_current()


func set_checkpoint() -> void:
	start_pos = position


func reset_after_fall() -> void:
	position = start_pos
	velocity = Vector2.ZERO
	state_machine.transition_by_name("Ragdoll")


func in_coyote_window() -> bool:
	return not is_on_floor() and last_floor_touch + COYOTE_TIME_MS > GameManager.now_ms()


func can_jump() -> bool:
	if not state_machine.active_state.can_jump:
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
	if ignore_inputs:
		return
	if event.is_action_pressed("jump") and can_jump():
		state_machine.transition_by_name("Jump")
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("interact"):
		if is_holding_prop:
			put_down_prop.call_deferred()
			get_viewport().set_input_as_handled()
		elif Activator.active_candidate and not Activator.active_candidate.manually_activated:
			Activator.active_candidate.activated.emit.call_deferred(Activator.active_candidate)
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ragdoll") and state_machine.get_active() != "Ragdoll":
			state_machine.transition_by_name.call_deferred("Ragdoll")
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("music_box"):
		state_machine.transition_by_name("UseMusicBox")
	if event.is_action_pressed("next_candidate") and Activator.candidates.size() > 1:
		Activator.rotate_candidate()


func _process(_delta: float) -> void:
	if is_on_floor():
		last_floor_touch = GameManager.now_ms()
	elif velocity != Vector2.ZERO:
		Activator.update_active_candidate()
	if perma_ragdoll and state_machine.get_active() != "Ragdoll":
		state_machine.call_deferred("transition_by_name", "Ragdoll")


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
	if not active_grab_box:
		return
	Log.debug(self, "finished pick up")
	is_holding_prop = active_grab_box.target_node
	active_grab_box.picked_up.emit(holding_hand)
	did_pick_up.emit(active_grab_box.target_node)
	Activator.update_active_candidate()


func put_down_prop() -> void:
	if is_holding_prop:
		if is_holding_prop.has_method("before_put_down"):
			await is_holding_prop.before_put_down()
		Log.info(self, "putting down:", is_holding_prop.name, active_grab_box.name)
		if is_holding_prop is MoveableRigidBody2D:
			is_holding_prop.set_next_linear_velocity(velocity)
		active_grab_box.put_down.emit()
		did_put_down.emit(active_grab_box.target_node)
		
		#if is_holding_prop and absf(velocity.x) > 50.0:
			#var velocity_deg := wrapf(rad_to_deg(velocity.angle()), -270.0, 90.0)
			#var impulse_angle := deg_to_rad(clampf(velocity_deg, -150.0, -30.0))
			#var impulse := Vector2.from_angle(impulse_angle) * 140.0
			#is_holding_prop.apply_impulse(impulse, active_grab_box.global_position - is_holding_prop.global_position)

		is_holding_prop = null
		active_grab_box = null
