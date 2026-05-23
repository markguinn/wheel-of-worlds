extends Parallax2D


@export var sway_vector := Vector2(25.0, 0.0)
@export var cycle_seconds := 10.0

var initial_offset: Vector2


func _ready() -> void:
	initial_offset = scroll_offset


func _process(_delta: float) -> void:
	var idx := PI * 2.0 * float(GameManager.now_ms()) / (1000.0 * cycle_seconds)
	scroll_offset = sin(idx) * sway_vector
