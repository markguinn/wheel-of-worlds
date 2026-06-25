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
	
	var cam_tween := create_tween()
	var cam: Camera2D = %Camera2D
	cam_tween.tween_property(cam, "global_position", %CameraTarget.global_position, 3.0)
	cam_tween.tween_property(player, "global_position", %PlayerTarget.global_position, 7.0)
	# shouldn't be needed but sometimes the gravity doesn't kick in right?
	cam_tween.parallel().tween_property(%Orb, "global_position", %PlayerTarget.global_position, 4.0)
	
	await get_tree().create_timer(3.0).timeout
	
	anim_player.play("cutscene")
	%EndPortal.activation_complete.connect(_on_cutscene_complete)


func _on_cutscene_complete() -> void:
	#VFX.white_out(VFX.LONG)
	pass


func take_fish_too() -> void:
	anim_player.stop(true)
	await get_tree().physics_frame
	anim_fish.reparent(%EndPortal.eye_bg)
	anim_fish.z_index = 0


func shake(amount: float) -> void:
	VFX.shake(VFX.LONG, amount)
	VFX.flash(VFX.SHORT, amount * 0.5, VFX.Flash.LIGHT)
