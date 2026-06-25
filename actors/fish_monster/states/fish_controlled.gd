class_name FishControlledState
extends StateNode

var fish: FishMonster


func _entered(_from_state: StateNode) -> void:
	if not target is FishMonster:
		Log.error(self, "this state needs a FishMonster target to work")
	fish = target
	#fish.gravity_scale = 0.0


func _process(_delta: float) -> void:
	fish.swim_particles.global_position.y = fish.territory_rect.position.y + fish.splash_offset
	

func can_transition_to(_to_state: StateNode) -> bool:
	return false
