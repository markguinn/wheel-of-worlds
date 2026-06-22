extends BirdBaseState


const GRAB_DISTANCE = 100.0

var attack_target: GrabBox
var entered_at: int

func _entered(_from: StateNode) -> void:
	entered_at = GameManager.now_ms()
	var min_dist := bird.max_target_distance
	var found_food := false
	attack_target = null
	Log.debug(bird, "starting attack. recently carried", bird.recently_carried)
	for node in get_tree().get_nodes_in_group("bird_targets"):
		if node in bird.recently_carried:
			Log.debug(bird, "skipping", node.target_node)
			
			continue

		var d := bird.global_position.distance_to(node.global_position)
		
		if node.target_node is BirdFood and d < bird.max_target_distance:
			if node.target_node.freeze:
				Log.debug(bird, "skipping frozen food", node.target_node)
				continue
			Log.debug(bird, "found food!", node.target_node)
			attack_target = node
			found_food = true
			break
		elif d < min_dist:
			attack_target = node
			min_dist = d

	if not attack_target or not attack_target.target_node:
		Log.debug(bird, "no attack target found")
		bird.recently_carried = []
		machine.transition_by_name("Flying")
	else:
		Log.debug(bird, "attack target", attack_target.target_node.name)
		destination = attack_target.global_position
		if not found_food and bird.sfx_squawk:
			bird.sfx_squawk.play()


func _process(delta: float) -> void:
	super._process(delta)
	if GameManager.now_ms() > entered_at + bird.attack_max_seconds * 1000:
		Log.debug(bird, "giving up on attack")
		machine.transition_by_name("Flying")


func _reached_destination() -> void:
	if bird.global_position.distance_to(attack_target.global_position) < GRAB_DISTANCE:
		Log.debug(bird, "reached target")
		bird.carried_obj = attack_target
		machine.transition_by_name("PickingUp")
	else:
		Log.debug(bird, "reached destination but didn't find food. retargeting")
		destination = attack_target.global_position
