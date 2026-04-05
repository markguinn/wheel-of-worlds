extends BirdBaseState


const MAX_DISTANCE = 1_000_000.0
const GRAB_DISTANCE = 100.0

var attack_target: Node2D


func _entered(_from: StateNode) -> void:
	# TODO: this might get tedious - can we automate it?
	var min_dist := MAX_DISTANCE
	attack_target = null
	for node in get_tree().get_nodes_in_group("bird_targets"):
		if node in bird.recently_carried:
			Log.debug(bird, "skipping", node)
			continue
		var d := bird.global_position.distance_to(node.global_position)
		if d < min_dist:
			attack_target = node
			min_dist = d

	if not attack_target:
		Log.debug(bird, "no attack target found")
		machine.transition_by_name("Flying")
	else:
		Log.debug(bird, "attack target", attack_target.name)
		# TODO: should we fix the position here? or track towards the prop even if it moves?
		destination = attack_target.global_position


# TODO: if it hits the orb or player it should yeet them I think?


func _reached_destination() -> void:
	if bird.global_position.distance_to(attack_target.global_position) < GRAB_DISTANCE:
		Log.debug(bird, "gotcha")
		bird.carried_obj = attack_target
		machine.transition_by_name("Carrying")
