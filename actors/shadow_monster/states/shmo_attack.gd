extends ShadowMonsterBaseState

const ATTACK_LENGTH_MS = 800

func _entered(_from_state: StateNode) -> void:
	monster.arm.arm_global_position = monster.target.global_position
	
func _process(_delta: float) -> void:
	if GameManager.now_ms() > entered_at + ATTACK_LENGTH_MS:
		machine.transition_by_name.call_deferred("Alert")
