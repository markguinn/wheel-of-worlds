class_name PlayerRagdollState
extends PlayerState


const STILLNESS_THRESHOLD = 1.0
const STILLNESS_WINDOW_MS = 1000


var last_ragdoll_movement := 0

# NOTE: these need to be in the same order as ragdoll_bodies
@onready var guidepoints: Array[Marker2D] = [
	%GuidePoints/Torso,
	%GuidePoints/ArmL,
	%GuidePoints/ArmR,
	%GuidePoints/LegL,
	%GuidePoints/LegR,
]
@onready var ragdoll_bodies: Array[RigidBody2D] = [
	%Ragdoll/Torso,
	%Ragdoll/HandL,
	%Ragdoll/HandR,
	%Ragdoll/FootL,
	%Ragdoll/FootR,
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
]

@onready var dizzy_particles: GPUParticles2D = %DizzyParticles


func init_state(_machine: StateMachine, _target: Node2D) -> void:
	super.init_state(_machine, _target)
	_disable_ragdoll_elements.call_deferred()


func _entered(_prev_state: StateNode) -> void:
	last_ragdoll_movement = Time.get_ticks_msec()
	_enable_ragdoll_elements()
	dizzy_particles.emitting = true
	if player.is_holding_prop:
		player.put_down_prop()


func _before_exit(_next_state: StateNode) -> void:
	_disable_ragdoll_elements()
	dizzy_particles.emitting = false

func _enable_ragdoll_elements() -> void:
	# make the animation player disconnect from controlling the guidepoints
	player.anim_player.active = false
	# don't do the normal collision
	player.shape.disabled = true
	
	# enable the ragdoll bodies and reset them to match the guidepoints
	for i in range(guidepoints.size()):
		ragdoll_bodies[i].global_position = guidepoints[i].global_position
		ragdoll_bodies[i].global_rotation = 0.0
		ragdoll_bodies[i].linear_velocity = player.velocity * randf_range(0.8, 1.2) if i > 0 else player.velocity
		ragdoll_bodies[i].angular_velocity = 0.0
		ragdoll_bodies[i].freeze = false
	for n in ragdoll_collision_shapes:
		n.disabled = false
	for n in ragdoll_remote_transforms:
		n.update_position = true
		n.update_rotation = true


func _disable_ragdoll_elements() -> void:
	# reset the rotation of the player in case it was changed by the ragdoll
	player.global_rotation = 0

	# restore the animation and player collision
	if player.anim_player:
		player.anim_player.active = true
	if player.shape:
		player.shape.disabled = false
	
	# disable the ragdoll bodies so they don't get in the way
	for n in ragdoll_bodies:
		n.freeze = true
	for n in ragdoll_collision_shapes:
		n.disabled = true
	for n in ragdoll_remote_transforms:
		n.update_position = false
		n.update_rotation = false


func _process(_delta: float) -> void:
	pass
	
func _physics_process(_delta: float) -> void:
	# we have to be careful here because:
	# 1) we want the torso rigid body to match up with a marker rather than the actual origin of the player node
	# 2) if we move or rotate the player, the rigid bodies also rotate
	# so we have to calculate the amount the player root needs to move to match up with the torso rigid body
	# and then subtract the same values from the rigid bodies to put them back the way they were
	var diff: Vector2 = ragdoll_bodies[0].global_position - guidepoints[0].global_position
	var rotation_diff: float = ragdoll_bodies[0].global_rotation - player.global_rotation

	player.global_position += diff
	player.global_rotation += rotation_diff
#
	for n in ragdoll_bodies:
		n.global_position -= diff
		n.global_rotation -= rotation_diff

	# when the player has stopped moving for a short time, switch back to idle
	if diff.length_squared() < STILLNESS_THRESHOLD:
		if Time.get_ticks_msec() > last_ragdoll_movement + STILLNESS_WINDOW_MS:
			machine.transition_by_name("Idle")
	else:
		last_ragdoll_movement = Time.get_ticks_msec()
