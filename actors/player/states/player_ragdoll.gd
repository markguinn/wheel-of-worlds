class_name PlayerRagdollState
extends PlayerState


const STILLNESS_THRESHOLD = 100.0
const STILLNESS_WINDOW_MS = 1000
const STANDUP_DIST = 80.0
const STANDUP_TIME = 0.2

var last_ragdoll_movement := 0
var temp_return_at := 0
var temp_return_to: StateNode = null
var temp_torso_velocity: Vector2 = Vector2.INF

# NOTE: these need to be in the same order as ragdoll_bodies
@onready var guidepoints: Array[Marker2D] = [
	%GuidePoints/Torso,
	%GuidePoints/ArmL,
	%GuidePoints/ArmR,
	%GuidePoints/LegL,
	%GuidePoints/LegR,
]
@onready var ragdoll_bodies: Array[PlayerRagdollBody] = [
	%Ragdoll/Torso,
	%Ragdoll/HandL,
	%Ragdoll/HandR,
	%Ragdoll/FootL,
	%Ragdoll/FootR,
]
@onready var ragdoll_bodies_mid: Array[RigidBody2D] = [
	#null,
	#%Ragdoll/ElbowL,
	#%Ragdoll/ElbowR,
	#%Ragdoll/KneeL,
	#%Ragdoll/KneeR,
]
@onready var ragdoll_remote_transforms: Array[RemoteTransform2D] = [
	%Ragdoll/HandL/RemoteTransform2D,
	%Ragdoll/HandR/RemoteTransform2D,
	%Ragdoll/FootL/RemoteTransform2D,
	%Ragdoll/FootR/RemoteTransform2D,
]
@onready var ragdoll_collision_shapes: Array[CollisionShape2D] = [
	%Ragdoll/Torso/CollisionShape2D,
	%Ragdoll/HandL/CollisionShape2D,
	%Ragdoll/HandR/CollisionShape2D,
	%Ragdoll/FootL/CollisionShape2D,
	%Ragdoll/FootR/CollisionShape2D,
	#%Ragdoll/ElbowL/CollisionShape2D,
	#%Ragdoll/ElbowR/CollisionShape2D,
	#%Ragdoll/KneeL/CollisionShape2D,
	#%Ragdoll/KneeR/CollisionShape2D,
]
@onready var guidepoints_container: GuidepointSyncingBehaviors = %GuidePoints
@onready var ragdoll_container: Node2D = %Ragdoll
@onready var dizzy_particles: GPUParticles2D = %DizzyParticles
@onready var sfx: PlayerSFX = %SFX


func init_state(_machine: StateMachine, _target: Node2D) -> void:
	super.init_state(_machine, _target)
	_init_ragdoll_elements.call_deferred()
	ragdoll_bodies[0].entered_kill_zone.connect(_on_entered_kill_zone)
	

func _entered(_prev_state: StateNode) -> void:
	last_ragdoll_movement = GameManager.now_ms()
	_enable_ragdoll_elements()
	if player.is_holding_prop:
		player.put_down_prop()


func _before_exit(_next_state: StateNode) -> void:
	_disable_ragdoll_elements()
	dizzy_particles.emitting = false
	player.velocity = ragdoll_bodies[0].linear_velocity
	temp_return_at = 0
	temp_return_to = null
	temp_torso_velocity = Vector2.INF


func _on_entered_kill_zone() -> void:
	Log.debug(self, "ragdoll entered water. resetting")
	machine.transition_by_name("Idle")
	player.reset_after_fall()
	


func _init_ragdoll_elements() -> void:
	# convert the relative paths to a remote path
	for t in ragdoll_remote_transforms:
		var n := t.get_node(t.remote_path)
		t.remote_path = n.get_path()
	for b in ragdoll_bodies:
		b.impact.connect(_on_impact)

	# move the ragdoll stuff outside of the player so it can move freely
	ragdoll_container.reparent(player.get_parent(), false)
	_disable_ragdoll_elements()


func _enable_ragdoll_elements() -> void:
	# make the animation player disconnect from controlling the guidepoints
	player.anim_player.active = false
	guidepoints_container.sync_legs_to_animated = false
	# don't do the normal collision
	player.shape.disabled = true
	player.shape2.disabled = true
	ragdoll_bodies[0].angular_damp = 30.0 if temp_return_at else 1.0

	# enable the ragdoll bodies and reset them to match the guidepoints
	for i in range(guidepoints.size()):
		var limb_velocity = player.velocity # * randf_range(0.8, 1.2) if i > 0 else player.velocity
		if i == 0 and temp_torso_velocity != Vector2.INF:
			limb_velocity = temp_torso_velocity
		ragdoll_bodies[i].set_next_global_position(guidepoints[i].global_position)
		ragdoll_bodies[i].set_next_global_rotation(0.0)
		ragdoll_bodies[i].set_next_linear_velocity(limb_velocity)
		ragdoll_bodies[i].set_next_angular_velocity(0.0)
		ragdoll_bodies[i].freeze = false
		if i < ragdoll_bodies_mid.size() and ragdoll_bodies_mid[i]:
			ragdoll_bodies_mid[i].set_next_global_position(guidepoints[i].global_position.lerp(guidepoints[0].global_position, 0.5))
			ragdoll_bodies_mid[i].set_next_global_rotation(0.0)
			ragdoll_bodies_mid[i].set_next_linear_velocity(player.velocity.lerp(limb_velocity, 0.5))
			ragdoll_bodies_mid[i].set_next_angular_velocity(0.0)
			ragdoll_bodies_mid[i].freeze = false

	for n in ragdoll_collision_shapes:
		n.disabled = false

	await get_tree().physics_frame

	for n in ragdoll_remote_transforms:
		n.set_deferred("update_position", true)
		n.set_deferred("update_rotation", true)


func _disable_ragdoll_elements() -> void:
	# reset the rotation of the player in case it was changed by the ragdoll
	player.global_rotation = 0

	# restore the animation and player collision
	if player.anim_player:
		player.anim_player.active = true
		guidepoints_container.sync_legs_to_animated = true
	if player.shape:
		player.shape.disabled = false
	if player.shape2:
		player.shape2.disabled = false
		
	
	# disable the ragdoll bodies so they don't get in the way
	for n in ragdoll_bodies:
		n.freeze = true
	for n in ragdoll_bodies_mid:
		if n:
			n.freeze = true
	for n in ragdoll_collision_shapes:
		n.disabled = true
	for n in ragdoll_remote_transforms:
		n.update_position = false
		n.update_rotation = false


# do a small animation to get up off the ground before returning
# to a non-ragdoll state so we're not stuck in the ground
func transition_before_exit(to_state: StateNode) -> void:
	dizzy_particles.emitting = false
	guidepoints_container.set_temp_smoothing(1.0, 500)
	if temp_return_at > 0 or to_state.name == "Fall":
		return
	
	sfx.play_stand_up()
	
	var body := ragdoll_bodies[0]
	body.freeze = true
	var tween := create_tween()
	tween.tween_property(body, "position", body.position + Vector2(0, -STANDUP_DIST), STANDUP_TIME)
	tween.parallel().tween_property(body, "rotation", 0.0, STANDUP_TIME)
	await tween.finished


func temporary_ragdoll(return_after_ms = 500, torso_velocity = Vector2.INF) -> void:
	temp_torso_velocity = torso_velocity
	# it looks funky to return to jump, so we special case that to go straight to fall
	temp_return_to = machine.get_state("Fall") if machine.active_state.name == "Jump" else machine.active_state
	temp_return_at = GameManager.now_ms() + return_after_ms
	machine.transition(self)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not transitioning_out:
		machine.transition_by_name("Idle")
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	pass # disable the default behaviors


func _physics_process(delta: float) -> void:
	var now_ms := GameManager.now_ms()
	var diff: Vector2 = ragdoll_bodies[0].global_position - guidepoints[0].global_position
	if ragdoll_remote_transforms[0].update_position:
		player.global_position += diff
		player.global_rotation = ragdoll_bodies[0].global_rotation

	# when the player has stopped moving for a short time, switch back to idle
	if diff.length() / delta < STILLNESS_THRESHOLD:
		if not transitioning_out and now_ms > last_ragdoll_movement + STILLNESS_WINDOW_MS:
			machine.transition_by_name("Idle")
	else:
		last_ragdoll_movement = now_ms

	if temp_return_at > 0 and now_ms > temp_return_at and not transitioning_out:
		machine.transition(temp_return_to)


func _on_impact(collision_point: Vector2, collision_velocity: Vector2, colliding_body: Node, _body_part: PlayerRagdollBody) -> void:
	Log.debug(self, "impact at", collision_point, "with", colliding_body.name, "at velocity", collision_velocity)
	var cv_len := collision_velocity.length()

	if not dizzy_particles.emitting and not temp_return_at:
		dizzy_particles.emitting = true

	var particles = player.dust_particles_l if player.dust_particles_r.emitting else player.dust_particles_r
	particles.global_position = collision_point
	particles.emitting = true

	if cv_len > 400:
		sfx.play_ragdoll_impact()
		# shake a little harder if we were moving faster (like from a long fall)
		VFX.shake(VFX.SHORT, VFX.TREMOR if cv_len < 800 else VFX.QUAKE)
