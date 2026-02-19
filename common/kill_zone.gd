class_name KillZone
extends Area2D

########################################################
## Add this to an Area2D to make a pit or water that the player
## and props can fall into. When this happens they'll either be
## reset to their starting position or destroyed.
########################################################


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.has_method("reset_after_fall"):
		body.reset_after_fall.call_deferred()
	else:
		body.queue_free()
