class_name WoodpeckerFleeState
extends StateNode

var woodpecker: Woodpecker
var speed := 5.0
var flee_seconds := 4

func _entered(_from_state: StateNode) -> void:
	if not target is Woodpecker:
		Log.error(self, "this state needs a Woodpecker target to work")
	woodpecker = target
	_animate.call_deferred()


func _process(delta: float) -> void:
	woodpecker.position.x -= speed
	woodpecker.position.y -= speed
	var timer := get_tree().create_timer(flee_seconds)
	timer.timeout.connect(_on_timer_complete)


func _animate() -> void:
	woodpecker.sprite.play("flee")


func _on_timer_complete() -> void:
	woodpecker.queue_free.call_deferred()
