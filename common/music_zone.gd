class_name MusicZone
extends Area2D

##########################################################
# Attach this to an Area2D to change the intensity of the
# music while the player is inside the zone.
##########################################################


@export var intensity := 2


func _ready() -> void:
	body_entered.connect(_on_body_enter)
	body_exited.connect(_on_body_exit)


func _on_body_enter(body: Node2D) -> void:
	if body is Player:
		AudioManager.set_music_intensity(intensity)


func _on_body_exit(body: Node2D) -> void:
	if body is Player:
		# TODO: we'll need to keep them separate this way. you could imagine
		# a stack or a keeping track of all the active ones in audio manager
		AudioManager.set_music_intensity(1)
