@tool
class_name GuidepointSyncingBehaviors
extends Node2D

const FOOT_MARKER_GROUND_OFFSET = 10


@export var sync_legs_to_animated := true
@export var is_left_arm_over_body := false : set=set_left_arm_inversion

@onready var ground_detector_l: RayCast2D = %GroundDetectorL
@onready var animated_leg_l: Marker2D = %GuidePoints/AnimatedLegL
@onready var leg_l: Marker2D = %GuidePoints/LegL

@onready var ground_detector_r: RayCast2D = %GroundDetectorR
@onready var animated_leg_r: Marker2D = %GuidePoints/AnimatedLegR
@onready var leg_r: Marker2D = %GuidePoints/LegR

@onready var dust_particles_l: CPUParticles2D = %DustParticlesL
@onready var dust_particles_r: CPUParticles2D = %DustParticlesR

@onready var skeleton: Skeleton2D = %Skeleton2D
@onready var hand_l_poly: Polygon2D = %Parts/HandL

# We animate one marker, but the skeleton2D solves from a second one
# This gives us freedom to place the feet realistically on slopes.
# In this function we sync the real leg markers to the animated ones,
# and then check them against the ground detector ray casts and adjust
# upwards if needed.
func _process(_delta: float) -> void:
	if sync_legs_to_animated:
		leg_r.position = animated_leg_r.position
		if ground_detector_r.is_colliding():
			var cp: Vector2 = ground_detector_r.get_collision_point()
			dust_particles_r.global_position = cp
			if cp.y < leg_r.global_position.y + FOOT_MARKER_GROUND_OFFSET:
				leg_r.global_position.y = cp.y - FOOT_MARKER_GROUND_OFFSET
				#leg_r.global_position = leg_r.global_position.lerp(cp, 0.5)
		ground_detector_r.global_position.x = animated_leg_r.global_position.x
		
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
