class_name FishPatrollingState
extends StateNode

@export var move_after_ms := 5000
@export var move_speed := 500.0
@export var min_patrolling_ms := 20_000
@export var attack_distance := 350.0
@export var vertical_range := 40.0

var last_move := 0
var entered_at := 0
var splash_x_offset: float = 0.0
var fish: FishMonster


func _entered(_from_state: StateNode) -> void:
	if not target is FishMonster:
		Log.error(self, "this state needs a FishMonster target to work")
	fish = target
	fish.gravity_scale = 0
	entered_at = GameManager.now_ms()
	_move.call_deferred()


func _before_exit(_to_state: StateNode) -> void:
	fish.sprite.position.y = 0
	fish.swim_particles.emitting = false


func _move() -> void:
	var dir := 1.0 if GameManager.get_player().global_position.x > fish.global_position.x else -1.0
	var target_y := fish.territory_rect.position.y + fish.patrol_offset
	var vy := (target_y - fish.global_position.y) / (move_after_ms / 1000.0)
	fish.set_next_linear_velocity(Vector2(move_speed * dir, vy))
	fish.swim_particles.emitting = true


func _process(_delta) -> void:
	var now := GameManager.now_ms()
	var d := target.global_position.distance_to(GameManager.get_player().global_position)
	fish.sprite.position.y = sin(now / 200.0) * vertical_range
	fish.swim_particles.global_position.y = fish.territory_rect.position.y + fish.splash_offset
	if splash_x_offset == 0.0:
		splash_x_offset = absf(fish.swim_particles.position.x)
	fish.swim_particles.position.x = splash_x_offset * signf(fish.linear_velocity.x)
		
	if now > last_move + move_after_ms:
		last_move = now
		_move()
	elif d < attack_distance and now > entered_at + min_patrolling_ms:
		Log.debug(self, d, attack_distance)
		machine.transition_by_name("Attacking")
