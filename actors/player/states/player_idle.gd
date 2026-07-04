class_name PlayerIdleState
extends PlayerState

const HUD_MS = 8000


func _entered(_from_state: StateNode) -> void:
	if player and player.anim_player:
		if player.is_holding_prop:
			player.anim_player.play("idle_carry", 0.4)
		else:
			player.anim_player.play("idle", 0.4)
		player.did_pick_up.connect(_on_picked_up)
		player.did_put_down.connect(_on_put_down)

func _before_exit(_to_state: StateNode) -> void:
	GameManager.hide_hud()
	if player.did_pick_up.is_connected(_on_picked_up):
		player.did_pick_up.disconnect(_on_picked_up)
		player.did_put_down.disconnect(_on_put_down)

func _on_picked_up(_node: Node2D) -> void:
	player.anim_player.play("idle_carry")

func _on_put_down(_node: Node2D) -> void:
	player.anim_player.play("idle", 0.4)


func _process(delta: float) -> void:
	super._process(delta)

	if GameManager.now_ms() > machine.last_state_change_ms + HUD_MS and not GameManager.is_hud_visible():
		GameManager.show_hud()

	if not is_zero_approx(_get_input_vector().x):
		machine.transition_by_name("Walk")
