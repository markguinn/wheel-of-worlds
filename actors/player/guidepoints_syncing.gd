@tool
class_name GuidepointSyncingBehaviors
extends Node2D

const FOOT_MARKER_GROUND_OFFSET = 10


@export var sync_legs_to_animated := true

@onready var ground_detector_r: RayCast2D = %GroundDetectorR
@onready var animated_leg_r: Marker2D = %GuidePoints/AnimatedLegR
@onready var leg_r: Marker2D = %GuidePoints/LegR
@onready var ground_detector_l: RayCast2D = %GroundDetectorL
@onready var animated_leg_l: Marker2D = %GuidePoints/AnimatedLegL
@onready var leg_l: Marker2D = %GuidePoints/LegL


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
			if cp.y < leg_r.global_position.y + FOOT_MARKER_GROUND_OFFSET:
				leg_r.global_position.y = cp.y - FOOT_MARKER_GROUND_OFFSET
				#leg_r.global_position = leg_r.global_position.lerp(cp, 0.5)
		ground_detector_r.global_position.x = animated_leg_r.global_position.x
		
		leg_l.position = animated_leg_l.position
		if ground_detector_l.is_colliding():
			var cp: Vector2 = ground_detector_l.get_collision_point()
			if cp.y < leg_l.global_position.y + FOOT_MARKER_GROUND_OFFSET:
				leg_l.global_position.y = cp.y - FOOT_MARKER_GROUND_OFFSET
				#leg_l.global_position = leg_l.global_position.lerp(cp, 0.5)
		ground_detector_l.global_position.x = animated_leg_l.global_position.x
