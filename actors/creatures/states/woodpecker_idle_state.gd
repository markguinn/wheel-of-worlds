class_name WoodpeckerIdleState
extends StateNode

var woodpecker: Woodpecker
var current: float	# current delta since last animation toggle
var next: float		# random target delta for next animation toggle

func _entered(_from_state: StateNode) -> void:
	if not target is Woodpecker:
		Log.error(self, "this state needs a Woodpecker target to work")
	woodpecker = target
	_reset_next()
	_connect_collision.call_deferred()


func _process(delta: float) -> void:
	current += delta
	if current > next:
		_toggle_animation()
		_reset_next()


func _connect_collision() -> void:
	woodpecker.area.body_entered.connect(_on_area_2d_body_entered)


func _on_area_2d_body_entered(_body: Node2D) -> void:
	woodpecker.area.body_entered.disconnect(_on_area_2d_body_entered)
	machine.transition_by_name("Flee")


func _toggle_animation() -> void:
	if woodpecker.sprite.is_playing():
		woodpecker.sprite.stop()
	else:
		woodpecker.sprite.play("idle")


func _reset_next() -> void:
	current = 0
	next = randf_range(1, 3)
