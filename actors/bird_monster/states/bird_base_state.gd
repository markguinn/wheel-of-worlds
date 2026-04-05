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


func _reached_destination() -> void:
	Log.warn(bird, "reached destination but state didn't implement anything to do")


func _process(delta: float) -> void:
	if not destination:
		return
	if bird.global_position.is_equal_approx(destination):
		_reached_destination()
	else:
		bird.global_position = bird.global_position.move_toward(destination, bird.fly_speed * delta)
