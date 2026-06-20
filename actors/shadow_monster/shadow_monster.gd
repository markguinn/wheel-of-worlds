class_name ShadowBlob
extends Node2D

const MAX_DIST = 1_000_000.0

@export var hover_speed: float = 30.0

@export var target: Node2D
@export var target_warning_distance: float = 800.
@export var target_attack_distance: float = 400.
@export_range(0.1, 5.0) var arm_speed: float = 0.9
@export var lightsource_distance_tolerated: float = 600.
@export var distance_needed_from_walls: float = 128.
@export var attack_cooldown_ms: int = 500
@export var alert_cooldown_ms: int = 500

var colliding_walls := 0

var gave_warning: bool = false

@export var patrol_path_follow: PathFollow2D = null
@export var patrol_speed: float = 20.0

@onready var arm: ShadowMonsterArm = $Arm
@onready var light_rays: Array[RayCast2D] = [
	$Rays/LightRay1,
	$Rays/LightRay2,
	$Rays/LightRay3,
]
@onready var target_ray: RayCast2D = $Rays/TargetRay
@onready var state_machine: StateMachine = $StateMachine

var primary_light: Node2D
var primary_light_dist: float
var target_dist: float

func _process(delta: float) -> void:
	if patrol_path_follow:
		patrol_path_follow.progress += delta * patrol_speed
	#if target: # Handle arm animation
		#var to_target: Vector2 = (target.global_position - global_position)
		#if to_target.length() < target_attack_distance:
			#$Arm.arm_global_position = target.global_position
		#elif to_target.length() < target_warning_distance:
			#if not gave_warning:
				#%ScreamSFX.play()
				#gave_warning = true
			#$Arm.arm_global_position = lerp($Arm.arm_global_position, lerp(global_position, target.global_position, 0.25), arm_speed)
		#else:
			#$Arm.arm_global_position = global_position
			#if gave_warning: get_tree().create_timer(0.5).timeout.connect(func(): gave_warning = false)
	#else: $Arm.arm_global_position = global_position


# patrol
# alert
# attack
# flee

func _physics_process(delta: float) -> void:
	# TODO: is there a faster way to do this?
	# would it be faster to just make a ray for every light?
	var close_lights: Array[Node2D] = []
	var light_dist: Array[float] = []
	for light_source: Node2D in get_tree().get_nodes_in_group("light_sources"):
		var dist: float = global_position.distance_to(light_source.global_position)
		for i in range(light_dist.size()):
			if dist < light_dist[i]:
				light_dist.insert(i, dist)
				close_lights.insert(i, light_source)
				dist = 0.0
				break
		if dist > 0.0:
			light_dist.append(dist)
			close_lights.append(light_source)

	primary_light = null
	for i in range(min(light_rays.size(), close_lights.size())):
		light_rays[i].target_position = close_lights[i].global_position - global_position
		if not light_rays[i].is_colliding() and not primary_light:
			primary_light = close_lights[i]
			primary_light_dist = light_dist[i]

	if target:
		target_ray.target_position = target.global_position - global_position
		if target_ray.is_colliding():
			target_dist = MAX_DIST
		else:
			target_dist = target_ray.target_position.length()
		
	#Log.debounced(self, "lights", primary_light, close_lights, light_dist)

		#var from_lightsource: Vector2 = (global_position - light_source.global_position)
		#var raycast_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			#light_source.global_position,
			#(
				#light_source.global_position
				#+ from_lightsource.normalized()  * lightsource_distance_tolerated
			#)
		#)
		#if target: raycast_query.exclude = [target.get_rid()]
		#var raycast_result_to_source: Dictionary = space_state.intersect_ray(raycast_query)
		#var raycast_result_to_shadow: Dictionary = space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
			#global_position,
			#global_position + from_lightsource,
		#))
		#if(
			#"position" in raycast_result_to_source and from_lightsource.length() < lightsource_distance_tolerated
			#and (
				#not "position" in raycast_result_to_shadow
				#or ((raycast_result_to_shadow.position - global_position).length() > distance_needed_from_walls)
			#)
		#):
			#global_position = lerp(
				#global_position,
				#global_position + from_lightsource,
				#hover_speed * delta
			#)


@export var impact_strength: float = 500.
func _on_palm_body_entered(body: Node) -> void:
	if body is Player:
		%HitSFX.play()
		VFX.shake(VFX.MID, VFX.QUAKE)
		var linear_velocity: Vector2 = (body.global_position - $Arm/Palm.global_position).normalized() * impact_strength
		body.velocity = linear_velocity * 2
		body.state_machine.transition_by_name.call_deferred("Ragdoll")
		state_machine.transition_by_name.call_deferred("Alert")


func byebye() -> void:
	var bye_duration: float = 5.
	var byebye_tween: Tween = $Skin.byebye(bye_duration)
	byebye_tween.tween_property(self, "modulate", Color.TRANSPARENT, bye_duration)
	byebye_tween.tween_callback(func(): queue_free())


# these are for the walls

func _on_body_area_body_entered(body: Node2D) -> void:
	colliding_walls += 1


func _on_body_area_body_exited(body: Node2D) -> void:
	colliding_walls -= 1
