extends Node2D


@export var required_stones := 3

@onready var block_zone: Area2D = $BlockZone
@onready var waterfall_particles: GPUParticles2D = $WaterfallParticles
@onready var waterfall_bottom: CPUParticles2D = $BottomSplash
@onready var waterfall_top: CPUParticles2D = $TopSplash
@onready var waterfall_sfx: AudioStreamPlayer2D = $WaterfallSFX

var remaining_stones: int
var starting_width: float
var waterfall_material: ParticleProcessMaterial
var is_first_stone := true

# NOTE: the waterfall state is automatically persistent because
# the stones are persistent. So when you reenter the level, the
# stones retrigger body_entered and the waterfall starts off closed


func _ready() -> void:
	block_zone.body_entered.connect(_on_stone_entered_block_zone)
	block_zone.body_exited.connect(_on_stone_exited_block_zone)
	remaining_stones = required_stones
	waterfall_material = waterfall_particles.process_material
	starting_width = waterfall_material.emission_sphere_radius


func _on_stone_entered_block_zone(_body: Node2D) -> void:
	remaining_stones -= 1
	_apply_blockage.call_deferred()
	if is_first_stone:
		_do_first_stone_animation()
		is_first_stone = false


func _on_stone_exited_block_zone(_body: Node2D) -> void:
	remaining_stones += 1
	_apply_blockage.call_deferred()



func _input(event: InputEvent) -> void:
	if GameManager.DEV_MODE and event is InputEventKey and event.pressed and not event.is_echo():
		match event.physical_keycode:
			KEY_1:
				is_first_stone = true
				remaining_stones = 3
			KEY_2:
				_on_stone_entered_block_zone(null)
			KEY_3:
				_on_stone_exited_block_zone(null)


func _do_first_stone_animation() -> void:
	_do_cam_tween($CamMarker1.global_position, 1.0)


func _do_final_stone_animation() -> void:
	_do_cam_tween($CamMarker2.global_position, 2.0)


func _do_cam_tween(to: Vector2, time = 0.5) -> void:
	var cfp: RemoteTransform2D = get_node_or_null("%CameraFollowsPlayer")
	var cam: Camera2D = get_viewport().get_camera_2d()
	if not cfp or not cam:
		Log.warn(self, "missing something", cfp, cam)
		return
	cfp.update_position = false
	cam.position_smoothing_enabled = false
	var old_pos := cam.global_position
	var cam_tween := create_tween()
	cam_tween.set_ease(Tween.EASE_OUT)
	cam_tween.set_trans(Tween.TRANS_SINE)
	cam_tween.tween_property(cam, "global_position", to, time)
	cam_tween.tween_property(cam, "global_position", old_pos, time)
	await cam_tween.finished
	cam.position_smoothing_enabled = true
	cfp.update_position = true


func _apply_blockage() -> void:
	if remaining_stones > 0:
		var r := inverse_lerp(0, required_stones, remaining_stones)
		waterfall_particles.amount_ratio = r
		waterfall_material.emission_sphere_radius = lerpf(0, starting_width, r)
		waterfall_sfx.volume_db = lerpf(-12.0, 12, r)
		Log.info(self, "waterfall diminished", remaining_stones, waterfall_particles.amount)
		waterfall_top.emitting = true
		await get_tree().create_timer(0.5).timeout
		waterfall_top.emitting = false
	else:
		Log.info(self, "waterfall stopped")
		waterfall_particles.amount_ratio = 0.01
		waterfall_material.emission_sphere_radius = 10
		waterfall_bottom.emitting = false
		waterfall_top.emitting = true
		waterfall_sfx.volume_db = -24.0
		for n in get_tree().get_nodes_in_group("waterfall_barriers"):
			if n is CollisionShape2D:
				n.disabled = true
			if n is Area2D:
				n.monitoring = false
				n.monitorable = false
			if n is StaticBody2D:
				n.collision_layer = 0
		_do_final_stone_animation()
