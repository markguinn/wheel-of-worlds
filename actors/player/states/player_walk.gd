class_name PlayerWalkState
extends PlayerState


func _entered(_from_state: StateNode) -> void:
	if player.is_holding_prop:
		player.anim_player.play("walk_carry", 0.4)
	else:
		player.anim_player.play("walk", 0.4)
	player.did_pick_up.connect(_on_picked_up)
	player.did_put_down.connect(_on_put_down)

func _before_exit(_to_state: StateNode) -> void:
	if player.did_pick_up.is_connected(_on_picked_up):
		player.did_pick_up.disconnect(_on_picked_up)
		player.did_put_down.disconnect(_on_put_down)

func _on_picked_up(_node: Node2D) -> void:
	player.anim_player.play("walk_carry")

func _on_put_down(_node: Node2D) -> void:
	player.anim_player.play("walk", 0.4)


func _process(delta: float) -> void:
	super._process(delta)
	if is_zero_approx(_get_input_vector().x):
		machine.transition_by_name("Idle")
