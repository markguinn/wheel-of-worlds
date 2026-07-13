class_name KillZone
extends Area2D

########################################################
## Add this to an Area2D to make a pit or water that the player
## and props can fall into. When this happens they'll either be
## reset to their starting position or destroyed.
########################################################

@export var splash: AudioStreamPlayer

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.has_method("reset_after_fall"):
		body.reset_after_fall.call_deferred()
	if body.get_script() and body.get_script().has_script_signal("entered_kill_zone"):
		body.emit_signal("entered_kill_zone")
	if splash:
		splash.play()
