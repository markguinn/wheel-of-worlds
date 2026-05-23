extends AnimatedSprite2D


const anim_for_state: Dictionary[Player.EmotionalState, String] = {
	Player.EmotionalState.SCARED: "scared",
	Player.EmotionalState.KNOCKED_OUT: "x",
}

@export var openTimeMin = 0.75
@export var openTimeMax = 3.5
@export var blinkTimeMin = 0.1
@export var blinkTimeMax = 0.3

var delay := 0.0
var parent_player: Player = null


func _ready() -> void:
	var n = get_parent()
	while n:
		if n is Player:
			parent_player = n
			break
		n = n.get_parent()


func _process(delta):
	var emotional_state: Player.EmotionalState = parent_player.emotional_state if parent_player else Player.EmotionalState.NEUTRAL
	if emotional_state == Player.EmotionalState.NEUTRAL:
		delay -= delta
		if delay <= 0:
			if animation == "default":
				play("blink")
				delay = randf_range(blinkTimeMin, blinkTimeMax)
			else:
				play("default")
				delay = randf_range(openTimeMin, openTimeMax)
	else:
		var expected_anim = anim_for_state.get(emotional_state, "default")
		if animation != expected_anim:
			play(expected_anim)
