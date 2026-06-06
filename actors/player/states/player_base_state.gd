class_name PlayerState
extends StateNode

const CAMERA_HORIZONTAL_OFFSET = 1.0
const TRIP_ROLL_DC = 0.1 # when you hit a low ledge, this is the probability you'll trip into ragdoll
const TRIP_ROLL_DEBOUNCE = 2000

const WALK_ACCEL = 0.2
const TURNING_ACCEL = 0.1
const WALL_BOUNCE_COOLDOWN_MS = 1000

const GRAVITY_MULTIPLIER = 1.8
const GRAVITY_DIRECTION = Vector2.DOWN

const ROT_TWEEN = 0.2
const PUSH_FORCE = 1.0 # Applied to the orb
const PLANK_FORCE = Vector2(0.2, 0.6) # Applied to the plank

@export var horizontal_speed := 250.0
@export var carrying_speed := 160.0
@export var wall_bounce_amount := 0.0
@export var wall_bounce_ms := 250
@export var can_jump := true
@export var trip_roll_dc := 0.05

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var player: Player

@onready var foot_ray: RayCast2D = %FootWallRay
@onready var shin_ray: RayCast2D = %ShinWallRay
@onready var wall_detector: RayCast2D = %WallDetector
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
		Log.error(self, "PlayerState needs the target to the be the player")


func _get_input_vector() -> Vector2:
	if player.ignore_inputs:
		return Vector2.ZERO
	return Input.get_vector("left", "right", "up", "down")


func _update_horizontal_movement(dir: Vector2, delta: float) -> void:
	var speed := carrying_speed if player.is_holding_prop else horizontal_speed
	var target_vx: float = dir.x * speed * player.speed_multiplier
	if Flags.walk_acceleration:
		# feels annoying to have too much delay when changing directions
		# this is imperfect though because it flips when you get to zero anyway. we can iterate more another time
		var accel_val : float = TURNING_ACCEL if player.velocity.x and signf(target_vx) != signf(player.velocity.x) else WALK_ACCEL
		player.velocity.x = move_toward(player.velocity.x, target_vx, delta * horizontal_speed / accel_val)
	else:
		player.velocity.x = target_vx


func _update_facing_direction(dir: Vector2) -> void:
	if dir.x < 0 and player.sprite.scale.x > 0:
		# TODO: I think we'll want to build this into the animations instead of using scale but this works for now
		player.sprite.scale.x = -1.0
	elif dir.x > 0 and player.sprite.scale.x < 0:
		player.sprite.scale.x = 1.0


func _update_camera_offset(dir: Vector2, _delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		if dir.x:
			cam.drag_horizontal_offset = CAMERA_HORIZONTAL_OFFSET * signf(dir.x)
		cam.position_smoothing_speed = 5.0 if absf(player.velocity.y) < 100.0 else 20.0


func _apply_gravity(delta: float) -> void:
	if not player.is_on_floor() and not player.in_coyote_window():
		player.velocity += GRAVITY_DIRECTION * gravity * GRAVITY_MULTIPLIER * delta
	if player.velocity.y > 0 and name != "Fall" and not player.is_on_floor():
		# this didn't look as cool as I'd hoped, but we could probably make it:
		#if name != "Jump" and player.is_holding_prop:
			#machine.transition_by_name("Ragdoll")
		#else:
		machine.transition_by_name("Fall")


var last_wall_bounce_ms := 0
func _bounce_off_walls() -> void:
	if is_zero_approx(player.velocity.x) or is_zero_approx(wall_bounce_amount) or not Flags.wall_bounce:
		return
	if wall_detector.is_colliding() and not GameManager.rate_limit(WALL_BOUNCE_COOLDOWN_MS, "wall_bounce"):
		#player.velocity.x = wall_detector.get_collision_normal().x * absf(player.velocity.x) * wall_bounce_amount
		#var torso_velocity := wall_detector.get_collision_normal() * player.velocity.length() * wall_bounce_amount
		var torso_velocity := player.velocity.bounce(wall_detector.get_collision_normal()) * wall_bounce_amount
		machine.get_state("Ragdoll").temporary_ragdoll(wall_bounce_ms, torso_velocity)


func _move_and_slide(delta: float) -> void:
	if player.is_holding_prop is Plank and Flags.plank_struggle_mode:
		var plank: Plank = player.is_holding_prop
		var plank_dir := 1.0 if plank.wall_detector.global_position.x > player.global_position.x else -1.0
		if plank.wall_detector.is_colliding() and plank_dir == signf(player.velocity.x):
			player.velocity.x = 0

	var v := player.velocity
	if player.move_and_slide():
		# bump up a little bit if you just hit a low ledge, but add a slight risk of tripping
		if is_zero_approx(player.velocity.x) and not is_zero_approx(v.x) and foot_ray.is_colliding() and not shin_ray.is_colliding():
			player.velocity = v
			if not GameManager.rate_limit(TRIP_ROLL_DEBOUNCE, "player_trip_roll"):
				var trip_roll := randf()
				Log.debug(self, "rolled trip save", trip_roll)
				if trip_roll <= trip_roll_dc:
					Log.info(self, "failed trip save", trip_roll)
					%SFX.play_tripped()
					machine.transition_by_name("Ragdoll")
			else:
				player.position.y -= 100.0 * delta
				# if we don't do this ugly special case, you can get stuck in a jump up there
				# because your velocity is instantly 0
				if name == "Jump":
					machine.transition_by_name("Walk")
		
		# TODO: this is ugly. replace it with a more flexible system
		# I tried a bunch of things here and they were all glitch and less fun than the original 
		for i in range(player.get_slide_collision_count()):
			var col = player.get_slide_collision(i)
			var obj = col.get_collider()
			if obj is Orb and player.is_on_floor():
				if machine.get_active() != "Push":
					#obj.set_next_linear_velocity(v / 2.0)
					machine.get_state("Push").start_pushing_orb(obj)
				#player.velocity = v / 2.0
				#obj.apply_impulse(col.get_normal() * -PUSH_FORCE)
				#if ground_detector.get_collider() != obj and sign(col.get_normal().x) != sign(v.x):
					#var force := col.get_normal().abs() * v * PUSH_FORCE * delta
					#print("force:", [force, col.get_normal().x, v.x])
					#obj.apply_force(force, col.get_position() - obj.global_position)
					#obj.apply_force(force)
			if obj is Plank:
				if v.y > 1.0 and not obj.is_uprightish():
					var force := col.get_normal().abs() * v * PLANK_FORCE
					#print("force:", [force, col.get_normal().x, v.x])
					obj.apply_impulse(force, col.get_position() - obj.global_position)


func _process(delta: float) -> void:
	var dir := _get_input_vector()
	_update_horizontal_movement(dir, delta)
	_update_facing_direction(dir)
	_update_camera_offset(dir, delta)
	_apply_gravity(delta)
	_move_and_slide(delta)
	_bounce_off_walls()
