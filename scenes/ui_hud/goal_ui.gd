class_name GoalUi
extends CanvasLayer

signal win_possible(start_ticks: int, end_ticks: int)
signal win_cancelled
signal win_complete

const MAX_DIST = 320.0
const WIN_DIST = 16.0
const WIN_TIME_MS = 1000

@export var artifacts: Array[GoalArtifact] = []
@onready var icons: Array[TextureRect] = [
	$Icons/BrownArtifact,
	$Icons/BlueArtifact,
	$Icons/WhiteArtifact,
]

var win_condition_started := 0

func _process(_delta: float) -> void:
	var d1 = artifacts[0].global_position.distance_to(artifacts[1].global_position)
	var d2 = artifacts[2].global_position.distance_to(artifacts[1].global_position)
	icons[0].anchor_left = 0.5 - clampf(d1 / MAX_DIST / 2, 0.0, 0.5)
	icons[0].anchor_right = 0.5 - clampf(d1 / MAX_DIST / 2, 0.0, 0.5)
	icons[2].anchor_left = 0.5 + clampf(d2 / MAX_DIST / 2, 0.0, 0.5)
	icons[2].anchor_right = 0.5 + clampf(d2 / MAX_DIST / 2, 0.0, 0.5)

	if d1 <= WIN_DIST and d2 <= WIN_DIST:
		var n := Time.get_ticks_msec()
		if win_condition_started < 0:
			pass # already won
		elif win_condition_started == 0:
			win_condition_started = n
			emit_signal("win_possible", n, n + WIN_TIME_MS)
		elif n >= win_condition_started + WIN_TIME_MS:
			emit_signal("win_complete")
			var t = create_tween().parallel()
			var icon_container: Control = $Icons
			t.tween_property(icon_container, "offset_top", 8, 0.2)
			t.tween_property(icon_container, "offset_bottom", 40, 0.2)			
	elif win_condition_started > 0:
		emit_signal("win_cancelled")
		win_condition_started = 0
