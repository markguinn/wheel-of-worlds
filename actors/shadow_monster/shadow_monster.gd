class_name ShadowBlob
extends Node2D

@export_range(0., 1.) var hover_speed: float = 0.3

@export var target: Node2D
@export var target_warning_distance: float = 800.
@export var target_attack_distance: float = 400.
@export_range(0.1, 5.0) var arm_speed: float = 0.9
@export var lightsource_distance_tolerated: float = 415.
@export var distance_needed_from_walls: float = 128.
var gave_warning: bool = false
func _process(_delta: float) -> void:
	if target: # Handle arm animation
		var to_target: Vector2 = (target.global_position - global_position)
		if to_target.length() < target_attack_distance:
			$Arm.arm_global_position = target.global_position
		elif to_target.length() < target_warning_distance:
			if not gave_warning:
				$Scream.play()
				gave_warning = true
			$Arm.arm_global_position = lerp($Arm.arm_global_position, lerp(global_position, target.global_position, 0.25), arm_speed)
		else:
			$Arm.arm_global_position = global_position
			if gave_warning: get_tree().create_timer(0.5).timeout.connect(func(): gave_warning = false)
	else: $Arm.arm_global_position = global_position

func _physics_process(delta: float) -> void:
	# Handle light sensor based movement
	var space_state = get_world_2d().direct_space_state
	for light_source in get_tree().get_nodes_in_group("light_sources"):
		var from_lightsource: Vector2 = (global_position - light_source.global_position)
		var raycast_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			light_source.global_position,
			(
				light_source.global_position
				+ from_lightsource.normalized()  * lightsource_distance_tolerated
			)
		)
		if target: raycast_query.exclude = [target.get_rid()]
		var raycast_result_to_source: Dictionary = space_state.intersect_ray(raycast_query)
		var raycast_result_to_shadow: Dictionary = space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + from_lightsource,
		))
		if(
			"position" in raycast_result_to_source and from_lightsource.length() < lightsource_distance_tolerated
			and (
				not "position" in raycast_result_to_shadow
				or ((raycast_result_to_shadow.position - global_position).length() > distance_needed_from_walls)
			)
		):
			global_position = lerp(
				global_position,
				global_position + from_lightsource,
				hover_speed * delta
			)


@export var impact_strength: float = 500.
func _on_palm_body_entered(body: Node) -> void:
	Log.debug(self, "contact with ", body.name)
	if body is Player and body.state_machine.get_active() != "Ragdoll":
		$Arm/Palm/HitSound.play()
		VFX.shake(VFX.MID, VFX.QUAKE)
		var linear_velocity: Vector2 = (body.global_position - $Arm/Palm.global_position).normalized() * impact_strength
		body.velocity = linear_velocity * 2
		body.state_machine.transition_by_name.call_deferred("Ragdoll")

func byebye() -> void:
	var bye_duration: float = 5.
	var byebye_tween: Tween = $Skin.byebye(bye_duration)
	byebye_tween.tween_property(self, "modulate", Color.TRANSPARENT, bye_duration)
	byebye_tween.tween_callback(func(): queue_free())
