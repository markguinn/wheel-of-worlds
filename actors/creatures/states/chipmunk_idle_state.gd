class_name ChipmunkIdleState
extends StateNode


var chipmunk: Chipmunk


func _entered(_from_state: StateNode) -> void:
	if not target is Chipmunk:
		Log.error(self, "this state needs  Chipmunk target to work")
	chipmunk = target
	_play_animation.call_deferred()
	_connect_collisions.call_deferred()


func _play_animation() -> void:
	chipmunk.animated_sprite_2d.play("idle")


func _connect_collisions() -> void:
	chipmunk.alert_area_2d.body_entered.connect(_on_alert_area_2d_body_entered)


func _disconnect_collisions() -> void:
	chipmunk.alert_area_2d.body_entered.disconnect(_on_alert_area_2d_body_entered)


func _on_alert_area_2d_body_entered(_body: Node2D) -> void:
	_disconnect_collisions()
	machine.transition_by_name("Alert")
