extends CavernArea

var player_present := false
var orb_present := false

@export var anim_player: AnimationPlayer
@onready var anim_fish: Node2D = %AnimatedFishMonster

func _on_body_enter(body: Node2D) -> void:
	if body is Player:
		super._on_body_enter(body)
		player_present = true
		body.state_machine.state_changed.connect(_on_player_state_change)
	elif body is Orb:
		orb_present = true
		body.remove_from_group("music_box_targets")


func _on_body_exit(body: Node2D) -> void:
	if body is Player:
		super._on_body_exit(body)
		player_present = false
		body.state_machine.state_changed.disconnect(_on_player_state_change)
	elif body is Orb:
		orb_present = false
		body.add_to_group("music_box_targets")


func _on_player_state_change(_from_state: StateNode, to_state: StateNode) -> void:
	if to_state.name == "UseMusicBox":
		if orb_present:
			to_state.effect_speed = 150.0
			to_state.effect_radius = 3000.0
			start_cutscene.call_deferred()
		else:
			cancel_music_box.call_deferred()


func cancel_music_box() -> void:
		await get_tree().create_timer(0.5).timeout
		var player = GameManager.get_player()
		if player and player.state_machine.active_state.name == "UseMusicBox":
			player.state_machine.transition_by_name("Idle")
			VFX.flash(VFX.MID, VFX.TREMOR, VFX.Flash.DARK)


func start_cutscene() -> void:
	var player = GameManager.get_player()
	if not player:
		push_error("what? where did you go?")
		return
	player.ignore_inputs = true
	%FishMonster.is_active = false
	%CameraFollowTransform.update_position = false
	%CameraFollowTransform.update_rotation = false
	%CameraFollowTransform.update_scale = false
	
	for n in get_tree().get_nodes_in_group("final_stones"):
		n.fixed = true
		n.freeze = true

	var cam_tween := create_tween()
	var cam: Camera2D = %Camera2D
	cam_tween.tween_property(cam, "global_position", %CameraTarget.global_position, 5.0)
	cam_tween.tween_property(player, "global_position", %PlayerTarget.global_position, 5.0)
	# shouldn't be needed but sometimes the gravity doesn't kick in right?
	cam_tween.parallel().tween_property(%Orb, "global_position", %PlayerTarget.global_position, 5.0)
	
	await get_tree().create_timer(3.0).timeout
	
	anim_player.play("cutscene")
	%EndPortal.activation_complete.connect(_on_cutscene_complete.call_deferred)


func _on_cutscene_complete() -> void:
	# TODO: wait a little bit, maybe fade in the music or something
	await VFX.white_out(VFX.LONG).finished
	Engine.time_scale = 1.0
	# TODO: tween audio
	await get_tree().create_timer(3.0).timeout
	# TODO: go to the final scene instead of the wheel
	GameManager.change_scene("res://stages/forest/final_scene.tscn", {"fade_out": false, "fade_in": false})


func take_fish_too() -> void:
	anim_player.stop(true)
	await get_tree().physics_frame
	anim_fish.reparent(%EndPortal.eye_bg)
	anim_fish.z_index = 0
	var t = create_tween()
	t.tween_property(anim_fish, "global_position", anim_fish.global_position + Vector2(50.0, 100.0), 1.0)


func set_time_scale(value: float, seconds: float) -> void:
	VFX.tween_time_scale(value, seconds)


func shake(amount: float) -> void:
	VFX.shake(VFX.LONG, amount)
	VFX.flash(VFX.SHORT, amount * 0.5, VFX.Flash.LIGHT)
