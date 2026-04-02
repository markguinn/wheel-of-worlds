class_name FishAttackingState
extends StateNode

@export var attack_ms := 20_000

var fish: FishMonster
var entered_at := 0


func _entered(_from_state: StateNode) -> void:
	if not target is FishMonster:
		Log.error(self, "this state needs a FishMonster target to work")
	fish = target
	fish.gravity_scale = 1.0
	entered_at = GameManager.now_ms()
	fish.jumping.connect(_on_jump)


func _before_exit(_to_state: StateNode) -> void:
	fish.jumping.disconnect(_on_jump)


func _on_jump() -> void:
	if GameManager.now_ms() > entered_at + attack_ms:
		machine.transition_by_name("Patrolling")
