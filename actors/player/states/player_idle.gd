class_name PlayerIdleState
extends PlayerState

const HUD_MS = 8000

@export var min_sfx_ms := 5_000
@export var max_sfx_ms := 10_000

var next_sfx_time: int
var face_change_time: int

func _entered(_from_state: StateNode) -> void:
	if player and player.anim_player:
		if player.is_holding_prop:
			player.anim_player.play("idle_carry", 0.4)
		else:
			player.anim_player.play("idle", 0.4)
		player.did_pick_up.connect(_on_picked_up)
		player.did_put_down.connect(_on_put_down)
		player.last_action_at = GameManager.now_ms()
	_pick_next_sfx()


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

	if (
		GameManager.now_ms() > player.last_action_at + HUD_MS and 
		not GameManager.is_hud_visible() and 
		not player.ignore_inputs
	):
		GameManager.show_hud()
	if (
		GameManager.now_ms() > next_sfx_time and
		not player.ignore_inputs
	):
		%SFX/Idle.play()
		_pick_next_sfx()
		player.emotional_state = Player.EmotionalState.SCARED
		face_change_time = GameManager.now_ms() + 500
	if GameManager.now_ms() > face_change_time:
		player.emotional_state = Player.EmotionalState.NEUTRAL

	if not is_zero_approx(_get_input_vector().x):
		machine.transition_by_name("Walk")


func _pick_next_sfx() -> void:
	next_sfx_time = GameManager.now_ms() + randi_range(min_sfx_ms, max_sfx_ms)
	Log.debug(self, "next sfx", next_sfx_time)
