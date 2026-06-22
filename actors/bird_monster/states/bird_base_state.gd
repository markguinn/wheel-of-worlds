class_name BirdBaseState
extends StateNode

var bird: BirdMonster
var destination: Vector2 = Vector2.INF


func init_state(_machine: StateMachine, _target: Node2D) -> void:
	super.init_state(_machine, _target)
	if _target is BirdMonster:
		bird = _target
	else:
		Log.error(self, "this state needs a BirdMonster as the target to work")


func _get_random_nest() -> Node2D:
	var i := randi_range(0, bird.nests.size() - 1)
	return bird.nests.get(i)


func _is_at_nest() -> bool:
	for n in bird.nests:
		if bird.global_position.is_equal_approx(n.global_position):
			return true
	return false


func _reached_destination() -> void:
	Log.warn(bird, "reached destination but state didn't implement anything to do")


func _process(delta: float) -> void:
	if not destination:
		return
	if bird.global_position.is_equal_approx(destination):
		_reached_destination()
		return
		
	var player := GameManager.get_player()
	if (
			player
			# are we too close to the player?
			and bird.global_position.distance_to(player.global_position) < bird.min_player_distance
			# only counts if you're looking at it
			#and signf(bird.global_position.x - player.global_position.x) == player.scale.x
			and not GameManager.rate_limit(500, "bird_escape")
	):
		# TODO: change animation to be more hostile?
		bird.sfx_squawk.play()
		var dir := Vector2(randf_range(-0.4, 0.4), -1.0)
		var dist := bird.fly_speed * randf_range(1.0, 2.0)
		destination = bird.global_position + dir * dist
		Log.debug(bird, "running away to", destination)
		if bird.carried_obj:
			Log.debug(bird, "dropping my thing", bird.carried_obj)
			bird.carried_obj.put_down.emit()
			bird.carried_obj = null

	bird.global_position = bird.global_position.move_toward(destination, bird.fly_speed * delta)
