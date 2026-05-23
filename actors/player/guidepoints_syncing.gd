@tool
class_name GuidepointSyncingBehaviors
extends Node2D

const FOOT_MARKER_GROUND_OFFSET = 10


@export var sync_legs_to_animated := true
@export var is_left_arm_over_body := false : set=set_left_arm_inversion

## If greater than 0, this controls how quickly the feet will move toward the
## animated markers for the legs. If set it should be high (e.g., 1000), but
## we probably want to leave it as zero. There are times when the code temporarily
## sets it though (e.g. when recovering from a ragdoll)
@export var smoothing := 0.0

@onready var ground_detector_l: RayCast2D = %GroundDetectorL
@onready var animated_leg_l: Marker2D = %GuidePoints/AnimatedLegL
@onready var leg_l: Marker2D = %GuidePoints/LegL

@onready var ground_detector_r: RayCast2D = %GroundDetectorR
@onready var animated_leg_r: Marker2D = %GuidePoints/AnimatedLegR
@onready var leg_r: Marker2D = %GuidePoints/LegR

@onready var dust_particles_l: CPUParticles2D = %DustParticlesL
@onready var dust_particles_r: CPUParticles2D = %DustParticlesR

@onready var skeleton: Skeleton2D = %Skeleton2D
@onready var hand_l_poly: Polygon2D = %Parts/ArmL

# We animate one marker, but the skeleton2D solves from a second one
# This gives us freedom to place the feet realistically on slopes.
# In this function we sync the real leg markers to the animated ones,
# and then check them against the ground detector ray casts and adjust
# upwards if needed.
func _process(delta: float) -> void:
	if sync_legs_to_animated:
		if smoothing > 0.0:
			leg_r.position = leg_r.position.move_toward(animated_leg_r.position, delta * smoothing)
		else:
			leg_r.position = animated_leg_r.position
		if ground_detector_r.is_colliding():
			var cp: Vector2 = ground_detector_r.get_collision_point()
			dust_particles_r.global_position = cp
			if cp.y < leg_r.global_position.y + FOOT_MARKER_GROUND_OFFSET:
				leg_r.global_position.y = cp.y - FOOT_MARKER_GROUND_OFFSET
				#leg_r.global_position = leg_r.global_position.lerp(cp, 0.5)
		ground_detector_r.global_position.x = animated_leg_r.global_position.x
		
		if smoothing > 0.0:
			leg_l.position = leg_l.position.move_toward(animated_leg_l.position, delta * smoothing)
		else:
			leg_l.position = animated_leg_l.position
		if ground_detector_l.is_colliding():
			var cp: Vector2 = ground_detector_l.get_collision_point()
			dust_particles_l.global_position = cp
			if cp.y < leg_l.global_position.y + FOOT_MARKER_GROUND_OFFSET:
				leg_l.global_position.y = cp.y - FOOT_MARKER_GROUND_OFFSET
				#leg_l.global_position = leg_l.global_position.lerp(cp, 0.5)
		ground_detector_l.global_position.x = animated_leg_l.global_position.x
		

func set_left_arm_inversion(v: bool) -> void:
	is_left_arm_over_body = v
	if skeleton:
		var mod_stack := skeleton.get_modification_stack()
		var mod_arm_l: SkeletonModification2DTwoBoneIK = mod_stack.get_modification(0)
		#if mod_arm_l.target_nodepath.get_name() # TODO: error maybe?
		mod_arm_l.flip_bend_direction = not v
		hand_l_poly.z_index = 1 if v else 0


var original_smoothing: float = -1.0
func set_temp_smoothing(seconds: float, speed = 500.0) -> void:
	if original_smoothing < 0.0:
		original_smoothing = smoothing
		smoothing = speed
		await get_tree().create_timer(seconds).timeout
		smoothing = original_smoothing
		original_smoothing = -1.0
	else:
		smoothing = speed
