class_name ShadowMonsterBaseState
extends StateNode

var monster: ShadowBlob
var entered_at: int

func init_state(_machine: StateMachine, _target: Node2D) -> void:
	super.init_state(_machine, _target)
	if _target is ShadowBlob:
		monster = _target
	else:
		Log.error(self, "this state needs a ShadowBlob as the target to work")


func _before_enter(_from_state: StateNode) -> void:
	entered_at = GameManager.now_ms()
