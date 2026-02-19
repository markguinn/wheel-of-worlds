extends Node


##########################################################
# Globally manage props that could be picked up
# but only make the closest one available. 


var candidates_for_holding: Array[GrabBox] = []


func add_candidate(obj: GrabBox) -> void:
	if not candidates_for_holding.has(obj):
		candidates_for_holding.append(obj)
		update_active_candidate()


func remove_candidate(obj: GrabBox) -> void:
	if candidates_for_holding.has(obj):
		if obj.state == GrabBox.State.ACTIVE_CANDIDATE:
			obj._release_active_candidate()
		candidates_for_holding.erase(obj)
		update_active_candidate()


func update_active_candidate() -> void:
	var player: Player = GameManager.get_player()
	if candidates_for_holding.size() == 0 or player.is_holding_prop:
		return

	var cur_active: GrabBox = null
	var next_active: GrabBox = null
	var min_dist: float = 1_000_000.0 # TODO: use constant when i have internet again
	for obj in candidates_for_holding:
		var my_dist = obj.target_node.global_position.distance_squared_to(player.global_position)
		if my_dist < min_dist:
			next_active = obj
		if obj.state == GrabBox.State.ACTIVE_CANDIDATE:
			cur_active = obj

	if cur_active != next_active:
		if cur_active:
			cur_active._release_active_candidate()
		if next_active:
			next_active._become_active_candidate()
