class_name ChipmunkFleeState
extends StateNode


var chipmunk: Chipmunk
var speed := 8.0
var flee_seconds := 4


func _entered(_from_state: StateNode) -> void:
	if not target is Chipmunk:
		Log.error(self, "this state needs  Chipmunk target to work")
	chipmunk = target
	chipmunk.animated_sprite_2d.play("flee")
	var timer := get_tree().create_timer(flee_seconds)
	timer.timeout.connect(_on_timer_complete)


func _process(_delta: float) -> void:
	chipmunk.position.x += speed


func _on_timer_complete() -> void:
	chipmunk.queue_free.call_deferred()
