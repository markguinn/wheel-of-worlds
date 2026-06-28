class_name ChipmunkAlertState
extends StateNode


var chipmunk: Chipmunk


func _entered(_from_state: StateNode) -> void:
	if not target is Chipmunk:
		Log.error(self, "this state needs  Chipmunk target to work")
	chipmunk = target
	chipmunk.animated_sprite_2d.play("alert")
	_connect_collisions.call_deferred()


func _connect_collisions() -> void:
	chipmunk.alert_area_2d.body_exited.connect(_on_alert_area_2d_body_exited)
	chipmunk.flee_area_2d.body_entered.connect(_on_flee_area_2d_body_entered)


func _disconnect_collisions() -> void:
	chipmunk.alert_area_2d.body_exited.disconnect(_on_alert_area_2d_body_exited)
	chipmunk.flee_area_2d.body_entered.disconnect(_on_flee_area_2d_body_entered)


func _on_alert_area_2d_body_exited(_body: Node2D) -> void:
	_disconnect_collisions()
	machine.transition_by_name("Idle")


func _on_flee_area_2d_body_entered(_body: Node2D) -> void:
	_disconnect_collisions()

	# Direction of flee
	if _body.position.x < chipmunk.position.x:
		chipmunk.flee_direction = 1
	else:
		chipmunk.flee_direction = -1

	machine.transition_by_name("Flee")
