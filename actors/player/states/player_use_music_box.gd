class_name PlayerUseMusicBox
extends PlayerState


@export var effect_radius := 1000.0
@export var effect_speed := 50.0

@onready var music_box_sfx: AudioStreamPlayer2D = %SFX/MusicBox


func can_enter(from_state: StateNode) -> bool:
	if not player.has_music_box:
		return false
	if from_state.name != "Idle":
		return false
	if player.is_holding_prop:
		return false
	return super.can_enter(from_state)


func _entered(_from_state: StateNode) -> void:
	AudioManager.pause_music()
	music_box_sfx.play()
	player.anim_player.play("use_music_box")


func _before_exit(_to_state: StateNode) -> void:
	music_box_sfx.stop()
	AudioManager.resume_music()


func _input(event: InputEvent) -> void:
	if event.is_action_released("music_box"):
		machine.transition_by_name("Idle")


# TODO: i think this should move to an inner node on the prop - a MusicBoxTarget or something that handles everything
# TODO: i think we want to freeze these?
# TODO: make a list at the beginning and fire/call methods on start/stop
# TODO: vfx - ghostly? zindex up? particles?
func _process(delta: float) -> void:
	for n: Node2D in get_tree().get_nodes_in_group("music_box_targets"):
		if player.global_position.distance_to(n.global_position) > effect_radius:
			continue
		if n.has_method("move_toward_start_pos"):
			n.move_toward_start_pos(delta)
		else:
			if "start_pos" in n:
				var next_pos = n.global_position.move_toward(n.start_pos, delta * 50.0)
				if n.has_method("set_next_global_position"):
					n.set_next_global_position(next_pos)
				else:
					n.global_position = next_pos
			if "start_rot" in n:
				var next_rot = rotate_toward(n.global_rotation, n.start_rot, delta)
				if n.has_method("set_next_global_rotation"):
					n.set_next_global_rotation(next_rot)
				else:
					n.global_rotation = next_rot
			if "linear_velocity" in n:
				n.linear_velocity = Vector2.ZERO
