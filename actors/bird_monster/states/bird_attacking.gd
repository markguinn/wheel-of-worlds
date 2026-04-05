extends StateNode


const MAX_DISTANCE = 1_000_000.0

var bird: BirdMonster
var destination: Vector2 = Vector2.INF
var attack_target: Node2D


func init_state(_machine: StateMachine, _target: Node2D) -> void:
	super.init_state(_machine, _target)
	if _target is BirdMonster:
		bird = _target
	else:
		Log.error(self, "this state needs a BirdMonster as the target to work")


func _entered(_from: StateNode) -> void:
	# TODO: this might get tedious - can we automate it?
	var min_dist := MAX_DISTANCE
	attack_target = null
	for node in get_tree().get_nodes_in_group("bird_targets"):
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


func _process(delta: float) -> void:
	if bird.global_position.is_equal_approx(destination):
		Log.debug(bird, "gotcha")
		# TODO: oh shit, we're going to need grabbox to work with other entities than the player. fuuuuuck
		machine.transition_by_name("Carrying")
	else:
		bird.global_position = bird.global_position.move_toward(destination, bird.fly_speed * delta)
	
