class_name PlayerState
extends StateNode

const CAMERA_HORIZONTAL_OFFSET = 1.2

const WALK_ACCEL = 0.2
const TURNING_ACCEL = 0.1

const GRAVITY_MULTIPLIER = 1.8
const GRAVITY_DIRECTION = Vector2.DOWN

const ROT_TWEEN = 0.2
const PUSH_FORCE = 2.5 # Applied to the orb
const PLANK_FORCE = Vector2(0.2, 0.6) # Applied to the plank

@export var horizontal_speed := 250.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var player: Player

@onready var ground_detector_r: RayCast2D = %GroundDetectorR
@onready var animated_leg_r: Marker2D = %GuidePoints/AnimatedLegR
@onready var leg_r: Marker2D = %GuidePoints/LegR
@onready var ground_detector_l: RayCast2D = %GroundDetectorL
@onready var animated_leg_l: Marker2D = %GuidePoints/AnimatedLegL
@onready var leg_l: Marker2D = %GuidePoints/LegL


func init_state(_machine: StateMachine, _target: Node2D) -> void:
	super.init_state(_machine, _target)
	if _target is Player:
		player = _target
	else:
		push_error("PlayerState needs the target to the be the player")


func _get_input_vector() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")


func _update_horizontal_movement(dir: Vector2, delta: float) -> void:
	var target_vx: float = dir.x * horizontal_speed * player.walk_multiplier
	# feels annoying to have too much delay when changing directions
	# this is imperfect though because it flips when you get to zero anyway. we can iterate more another time
	var accel_val : float = TURNING_ACCEL if player.velocity.x and signf(target_vx) != signf(player.velocity.x) else WALK_ACCEL
	player.velocity.x = move_toward(player.velocity.x, target_vx, delta * horizontal_speed / accel_val)


func _update_facing_direction(dir: Vector2) -> void:
	if dir.x < 0 and player.sprite.scale.x > 0:
		# TODO: I think we'll want to build this into the animations instead of using scale but this works for now
		player.sprite.scale.x = -1.0
	elif dir.x > 0 and player.sprite.scale.x < 0:
		player.sprite.scale.x = 1.0


func _update_camera_offset(dir: Vector2) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and dir.x:
		cam.drag_horizontal_offset = CAMERA_HORIZONTAL_OFFSET * signf(dir.x)


func _apply_gravity(delta: float) -> void:
	if not player.is_on_floor() and not player.in_coyote_window():
		player.velocity += GRAVITY_DIRECTION * gravity * GRAVITY_MULTIPLIER * delta
	if player.velocity.y > 0 and name != "Fall":
		# this didn't look as cool as I'd hoped, but we could probably make it:
		#if name != "Jump" and player.is_holding_prop:
			#machine.transition_by_name("Ragdoll")
		#else:
		machine.transition_by_name("Fall")


func _move_and_slide(_delta: float) -> void:
	var v := player.velocity
	if player.move_and_slide():
		# TODO: this is ugly. replace it with a more flexible system
		# I tried a bunch of things here and they were all glitch and less fun than the original 
		for i in range(player.get_slide_collision_count()):
			var col = player.get_slide_collision(i)
			var obj = col.get_collider()
			if obj is Orb:
				obj.apply_impulse(col.get_normal() * -PUSH_FORCE)
				#if ground_detector.get_collider() != obj and sign(col.get_normal().x) != sign(v.x):
					#var force := col.get_normal().abs() * v * PUSH_FORCE * delta
					#print("force:", [force, col.get_normal().x, v.x])
					#obj.apply_force(force, col.get_position() - obj.global_position)
					#obj.apply_force(force)
			if obj is Plank:
				if v.y > 1.0:
					var force := col.get_normal().abs() * v * PLANK_FORCE
					#print("force:", [force, col.get_normal().x, v.x])
					obj.apply_impulse(force, col.get_position() - obj.global_position)


func _process(delta: float) -> void:
	var dir := _get_input_vector()
	_update_horizontal_movement(dir, delta)
	_update_facing_direction(dir)
	_update_camera_offset(dir)
	_apply_gravity(delta)
	_move_and_slide(delta)
