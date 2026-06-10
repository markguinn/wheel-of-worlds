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
		AudioManager.push_music_intensity(intensity)


func _on_body_exit(body: Node2D) -> void:
	if body is Player:
		AudioManager.pop_music_intensity(intensity)
