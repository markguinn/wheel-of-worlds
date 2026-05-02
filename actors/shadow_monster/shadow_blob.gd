class_name ShadowBlob
extends Node2D

@export var point_probes: Array[ShadowProbe]
@export var test_probes: Array[ShadowProbe]
@export var probe_radius_px: float = 100.
@export var loops_to_wait_for_probes: int = 5
@export var line: Line2D
@export_range(0., 1.) var hover_speed: float = 0.3

## Measurements for light at position: {"pos": Vector2, "light": float}
var light_measurements: Array[Dictionary] = []

func _scatter_probe(array: Array[ShadowProbe], i: int, angle_increment: float, radius: float = probe_radius_px) -> void:
	var current_angle = i * angle_increment + randf() * angle_increment
	var probe_vector = Vector2(sin(current_angle), cos(current_angle)) * radius * randf()
	var space_state = get_world_2d().direct_space_state
	var raycast_result = space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
		global_position, global_position + probe_vector
	))
	if "position" in raycast_result:array[i].global_position = raycast_result.position
	else: array[i].global_position = global_position + probe_vector
	$DebugLine2.points[i] = array[i].global_position

func _ready() -> void:
	assert(point_probes.size() == line.get_point_count(), "Probe count must match line point count!")
	assert(test_probes.size() == point_probes.size(), "Probe count must match!")
	assert(test_probes.size() == $DebugLine2.get_point_count(), "Probe count must match line point count!")
	
	# Set initial position of shadow probes
	var angle_increment = 2. * PI / float(point_probes.size())
	for i in point_probes.size():
		_scatter_probe(point_probes, i, angle_increment)
		light_measurements.push_back({"pos": point_probes[i].global_position, "light": point_probes[i].lit_value})
		_scatter_probe(test_probes, i, angle_increment)
		light_measurements.push_back({"pos": test_probes[i].global_position, "light": test_probes[i].lit_value})
	if debug_image: _init_debug_image()

@export var shadow_value_threshold: float = -0.4
@export var target: Node2D
@export var target_warning_distance: float = 800.
@export var target_attack_distance: float = 400.
@export_range(0.1, 5.0) var arm_speed: float = 0.9
var loop_count_in_probe_state: int = 0
func _process(_delta: float) -> void:
	if target: # Handle arm animation
		var to_target: Vector2 = (target.global_position - global_position)
		if to_target.length() < target_attack_distance:
			$Arm.arm_global_position = target.global_position
		elif to_target.length() < target_warning_distance:
			$Arm.arm_global_position = lerp($Arm.arm_global_position, lerp(global_position, target.global_position, 0.25), arm_speed)
		else: $Arm.arm_global_position = global_position

	# Handle light sensor based movement
	if loop_count_in_probe_state < loops_to_wait_for_probes:
		loop_count_in_probe_state += 1
		return

	# Only execute every `loops_to_wait_for_probes` loops
	loop_count_in_probe_state = 0
	var angle_increment = 2. * PI / float(point_probes.size())
	var center_position: Vector2 = Vector2.ZERO
	for i in test_probes.size():
		# Check and compare probes to currently established boundary points!
		var distance_to_probe: float = (test_probes[i].global_position - global_position).length()
		if( # Probe is darker, than the current point
			test_probes[i].lit_value < point_probes[i].lit_value
			or ( # probe is at the same light level, but further away
				test_probes[i].lit_value == point_probes[i].lit_value
				and(distance_to_probe >= (point_probes[i].global_position - global_position).length())
			) # Test probe is in a better position than the probe
		): point_probes[i].global_position = test_probes[i].global_position
		light_measurements[i] = {"pos": point_probes[i].global_position, "light": point_probes[i].lit_value}
		light_measurements[point_probes.size() + i] = {"pos": test_probes[i].global_position, "light": test_probes[i].lit_value}

		# Scatter the test probes again
		_scatter_probe(test_probes, i, angle_increment, 250.)

		# add some offset to the lines
		$DebugLine2.points[i] = test_probes[i].global_position + Vector2(512, 0)
		
		# Move Points closer to darkness based on mesurements if the point is in light
		if shadow_value_threshold < point_probes[i].lit_value:
			var to_shadow: Vector2 = ShadowCompass.get_direction_to_darkness(
				light_measurements, $CenterProbe.lit_value, point_probes[i].global_position
			) * 10.
			if (point_probes[i].global_position + to_shadow - global_position).length() <= probe_radius_px:
				point_probes[i].global_position += to_shadow

		line.points[i] = point_probes[i].global_position
		center_position += point_probes[i].global_position

	center_position /= float(point_probes.size())
	global_position = lerp(global_position, center_position, hover_speed)
	if debug_image: _update_debug_image()  # repaint after every compare cycle

@export var impact_strength: float = 500.
func _on_palm_body_entered(body: Node) -> void:
	Log.debug(self, "contact with ", body.name)
	if body is Player and body.state_machine.get_active() != "Ragdoll":
		$Arm/Palm/HitSound.play()
		VFX.shake(VFX.MID, VFX.QUAKE)
		var linear_velocity: Vector2 = (body.global_position - $Arm/Palm.global_position).normalized() * impact_strength
		body.velocity = linear_velocity * 2
		body.state_machine.transition_by_name.call_deferred("Ragdoll")

#region debug image
@export var debug_image: bool = false

const DEBUG_IMAGE_SIZE = 512
const DEBUG_IMAGE_HALF = DEBUG_IMAGE_SIZE / 2.
const DEBUG_IMAGE_WORLD_SIZE = 250.

# -- debug image --
var _debug_image: Image

func _init_debug_image() -> void:
	_debug_image = Image.create(DEBUG_IMAGE_SIZE, DEBUG_IMAGE_SIZE, false, Image.FORMAT_RGBA8)
	_debug_image.fill(Color(0, 0, 0, 1))
	$DebugSprite.texture = ImageTexture.create_from_image(_debug_image)

## 0 => blue, 1 ==> red
func heat_color(t: float) -> Color:
	return Color.from_hsv(t * 0.66, 1.0, 1.0)

# Call this after every measurement cycle to repaint the debug image
@export var debug_image_clear: float = 0.001
var debug_min_light: float = 0.
var debug_max_light: float = 0.
func _update_debug_image() -> void:
	if 0. < debug_image_clear: for x in DEBUG_IMAGE_SIZE: for y in DEBUG_IMAGE_SIZE:
		_debug_image.set_pixel(x,y, lerp(_debug_image.get_pixel(x,y), Color(0, 0, 0,), debug_image_clear))

	# Paint where probes currently sit (their last scatter position)
	for probes in [point_probes, test_probes]: for probe in probes:
		debug_min_light = min(probe.lit_value, debug_min_light)
		debug_max_light = max(probe.lit_value - debug_min_light, debug_max_light)
		_paint_sample(probe.global_position, (probe.lit_value - debug_min_light) / debug_max_light)

	$DebugSprite.texture = ImageTexture.create_from_image(_debug_image)


# Converts a world position → pixel, then paints a 3x3 cross with a heat color
func _paint_sample(world_pos: Vector2, light_value: float) -> void:
	# Map world offset relative to this node's origin → pixel space
	var offset: Vector2 = world_pos - global_position
	# Scale so DEBUG_IMAGE_WORLD_SIZE maps to the image edge
	var cross_scale: float = float(DEBUG_IMAGE_HALF) / DEBUG_IMAGE_WORLD_SIZE
	var px: float = int(offset.x * cross_scale) + DEBUG_IMAGE_HALF
	var py: float = int(offset.y * cross_scale) + DEBUG_IMAGE_HALF

	if px < 0 or px >= DEBUG_IMAGE_SIZE or py < 0 or py >= DEBUG_IMAGE_SIZE:
		return
	_debug_image.set_pixel(DEBUG_IMAGE_SIZE - round(px), DEBUG_IMAGE_SIZE - round(py), heat_color(light_value))
#endregion
