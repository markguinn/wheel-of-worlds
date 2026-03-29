class_name FishPatrollingState
extends StateNode

@export var move_after_ms := 5000
@export var move_speed := 500.0
@export var min_patrolling_ms := 20_000
@export var attack_distance := 350.0
@export var vertical_range := 40.0

var last_move := 0
var entered_at := 0
var fish: FishMonster


func _entered(_from_state: StateNode) -> void:
	if not target is FishMonster:
		Log.error(self, "this state needs a FishMonster target to work")
	fish = target
	fish.gravity_scale = 0
	#_move_to_top.call_deferred()
	entered_at = GameManager.now_ms()
	_move.call_deferred()


func _before_exit(_to_state: StateNode) -> void:
	fish.sprite.offset.y = 0


#func _move_to_top() -> void:
	#var water_top = Vector2(fish.global_position.x, fish.territory_rect.position.y)
	#fish.set_next_global_position(water_top)
	#fish.set_next_linear_velocity(Vector2.ZERO)
	#fish.gravity_scale = 0
	#_move()


func _move() -> void:
	#var dir := 1.0 if fish.linear_velocity.x > 0 else -1.0
	var dir := 1.0 if GameManager.get_player().global_position.x > fish.global_position.x else -1.0
	var vy := (fish.territory_rect.position.y - fish.global_position.y) / (move_after_ms / 1000)
	Log.debug(self, "vy", vy)
	fish.set_next_linear_velocity(Vector2(move_speed * dir, vy))


func _process(_delta) -> void:
	var now := GameManager.now_ms()
	var d := target.global_position.distance_to(GameManager.get_player().global_position)
	fish.sprite.offset.y = sin(now / 200.0) * vertical_range
	
	if now > last_move + move_after_ms:
		last_move = now
		_move()
	elif d < attack_distance and now > entered_at + min_patrolling_ms:
		Log.debug(self, d, attack_distance)
		machine.transition_by_name("Attacking")
