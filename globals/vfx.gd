extends Node

#################################################################
# Global VFX (screenshake etc) and shared constants.
# Common utility methods are also welcome here.
#################################################################

const SHAKE_SPEED = 2.0
const STRENGTH_MULTIPLIER = 24.0 # convert 1.0 strength to pixels

# Intensity constants
const FREAK_OUT = 1.5
const QUAKE = 1.0
const TREMOR = 0.5

# Timing constants
const SHORT = 0.3
const MID = 0.7
const LONG = 1.0
const EXTENDED = 2.0

# Types of screen flash. See "flash" method below for details.
enum Flash { NONE, NEUTRAL, LIGHT, DARK, STARK, BLAND }


@onready var noise := FastNoiseLite.new()
var shake_strength: float = 0.0
var shake_decay: float = 1.0
var flash_tween: Tween

# allows the user to turn down shaking
var shake_volume_setting := 1.0

var baseline_bloom := 0.0 
var baseline_brightness := 1.0
var baseline_contrast := 1.0
var baseline_saturation := 1.0


func set_baseline(bloom: float, brightness: float, contrast: float, saturation: float, apply = true) -> void:
	Log.info(self, "set vfx baseline", bloom, brightness, contrast, saturation)
	baseline_bloom = bloom
	baseline_brightness = brightness
	baseline_contrast = contrast
	baseline_saturation = saturation
	var env := _get_world_env()
	if env and apply:
		env.environment.glow_bloom = baseline_bloom
		env.environment.adjustment_brightness = baseline_brightness
		env.environment.adjustment_contrast = baseline_contrast
		env.environment.adjustment_saturation = baseline_saturation


func set_shake_volume(value: float) -> void:
	shake_volume_setting = value


## Timesaver for shake + flash. Use flash_intensity_ratio if you want a stronger shake than flash.
func hit(seconds = MID, intensity = QUAKE, flash_type = Flash.NEUTRAL, flash_intensity_ratio = 1.0, controller_shake = true) -> void:
	shake(seconds, intensity, controller_shake)
	if flash_type != Flash.NONE:
		flash(seconds, intensity * flash_intensity_ratio, flash_type)


## Screen shake with optional controller shake
func shake(seconds = MID, intensity = QUAKE, controller_shake = true) -> void:
	var new_strength = intensity * STRENGTH_MULTIPLIER * shake_volume_setting
	if new_strength <= shake_strength or seconds <= 0.0:
		return
	shake_strength = new_strength
	shake_decay = new_strength / seconds

	var weak_vibes := 0.0
	var strong_vibes := 0.0
	if intensity > TREMOR:
		strong_vibes = clampf((intensity - 0.5) * 2.0, 0.0, 1.0)
	else:
		weak_vibes = clampf(intensity * 2.0, 0.0, 1.0)
	if controller_shake:
		Input.start_joy_vibration(0, weak_vibes, strong_vibes, seconds)


## Screen flash only
## NEUTRAL is only bloom. 
## LIGHT/DARK adds brightness.
## STARK and BLAND add saturation as well.
## We'll probably need to tweak these as the real art and lighting evolves.
func flash(seconds = MID, intensity = QUAKE, type = Flash.NEUTRAL) ->void:
	var env := _get_world_env()
	if env and type != Flash.NONE:
		if flash_tween and flash_tween.is_running():
			flash_tween.stop()
		flash_tween = create_tween()
		flash_tween.set_ease(Tween.EASE_IN)
		#flash_tween.set_parallel(true)
		env.environment.glow_bloom = intensity
		match type:
			Flash.LIGHT:
				env.environment.adjustment_brightness = 1.0 + 2.0 * intensity
			Flash.DARK:
				env.environment.glow_bloom = 0.0 # bloom doesn't look nice with this one
				env.environment.adjustment_brightness = 1.0 - intensity * 1.2
			Flash.STARK:
				env.environment.adjustment_contrast = 1.0 + intensity * 0.5
				env.environment.adjustment_saturation = 1.0 + intensity * 5.0
			Flash.BLAND:
				env.environment.adjustment_saturation = 1.0 - intensity
		flash_tween.tween_property(env.environment, "glow_bloom", baseline_bloom, seconds)
		flash_tween.parallel().tween_property(env.environment, "adjustment_brightness", baseline_brightness, seconds)
		flash_tween.parallel().tween_property(env.environment, "adjustment_contrast", baseline_contrast, seconds)
		flash_tween.parallel().tween_property(env.environment, "adjustment_saturation", baseline_saturation, seconds)


func white_out(seconds = MID) -> Tween:
	var env := _get_world_env()
	var screen := _get_fade_screen_rect()
	var tween := get_tree().create_tween()
	if not env and not screen:
		return tween
	tween.set_ease(Tween.EASE_IN)
	if env:
		tween.tween_property(env.environment, "glow_bloom", 1.0, seconds)
		tween.parallel().tween_property(env.environment, "glow_intensity", 8.0, seconds)
		tween.parallel().tween_property(env.environment, "adjustment_brightness", 8.0, seconds)
	if screen:
		screen.color = Color.TRANSPARENT
		screen.show()
		tween.parallel().tween_property(screen, "color", Color.WHITE, seconds)
	return tween


func white_in(seconds = MID) -> Tween:
	var env := _get_world_env()
	var screen := _get_fade_screen_rect()
	var tween := get_tree().create_tween()
	if not env and not screen:
		return tween
	tween.set_ease(Tween.EASE_IN)
	if env:
		tween.tween_property(env.environment, "glow_bloom", baseline_bloom, seconds)
		tween.parallel().tween_property(env.environment, "glow_intensity", 0.5, seconds)
		tween.parallel().tween_property(env.environment, "adjustment_brightness", baseline_brightness, seconds)
	if screen:
		screen.color = Color.WHITE
		screen.show()
		tween.parallel().tween_property(screen, "color", Color.TRANSPARENT, seconds)
		await tween.finished
		screen.hide()
	return tween


var slomo_tween: Tween
func slomo(seconds = MID, intensity = QUAKE) -> Tween:
	Engine.time_scale = lerpf(1.0, 0.1, intensity)
	return tween_time_scale(1.0, seconds)


func tween_time_scale(value: float, seconds = MID) -> Tween:
	if slomo_tween and not slomo_tween.finished:
		slomo_tween.stop()
	slomo_tween = get_tree().create_tween()
	slomo_tween.set_ease(Tween.EASE_IN_OUT)
	slomo_tween.set_trans(Tween.TRANS_SINE)
	slomo_tween.tween_property(Engine, "time_scale", value, seconds)
	return slomo_tween


## Fade the whole screen or a single node in or out
# TODO: this doesn't actually fade the title screen in and out, which is weird
# It's because it's a canvas layer, which isn't affected by the modulate on the container or the root node
# and doesn't have a modulate property of its own.
func fade(seconds = MID, node = null, to_color = Color.TRANSPARENT) -> Tween:
	if not node:
		node = GameManager.get_container().get_parent()
	var tween = node.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(node, "modulate", to_color, seconds)
	return tween


## Fade a given node to transparency or fade the whole screen to black
func fade_out(seconds = MID, node = null) -> Tween:
	return fade(seconds, node, Color.TRANSPARENT if node else Color.BLACK)


## Fade a given node (or the whole screen) from its current modulate value to white
func fade_in(seconds = MID, node = null):
	return fade(seconds, node, Color.WHITE)


func _get_world_env() -> WorldEnvironment:
	return get_tree().get_first_node_in_group("world_environment")


func _get_fade_screen_rect() -> ColorRect:
	return get_tree().get_first_node_in_group("fade_screen")


func _process(delta: float) -> void:
	var cam = get_viewport().get_camera_2d()
	if not cam: return
	if shake_strength > 0.0:
		shake_strength = move_toward(shake_strength, 0.0, shake_decay * delta)
		var noise_idx := GameManager.now_ms() * SHAKE_SPEED
		var shake_offset := Vector2(
			noise.get_noise_2d(1, noise_idx),
			noise.get_noise_2d(100, noise_idx),
		)
		cam.offset = shake_offset * shake_strength


# This is just for testing. We should remove it before release
#func _input(event: InputEvent) -> void:
	#if GameManager.DEV_MODE and event is InputEventKey and event.pressed and not event.is_echo():
		#match event.physical_keycode:
			#KEY_1:
				#slomo(LONG)
			#KEY_2:
				#hit(LONG, QUAKE, Flash.NEUTRAL)
			#KEY_3:
				#hit(LONG, QUAKE, Flash.LIGHT)
			#KEY_4:
				#hit(LONG, QUAKE, Flash.DARK)
			#KEY_5:
				#hit(LONG, QUAKE, Flash.STARK)
			#KEY_6:
				#hit(LONG, QUAKE, Flash.BLAND)
			#KEY_7:
				#flash(MID, MID, Flash.NEUTRAL)
