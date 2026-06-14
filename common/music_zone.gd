class_name MusicZone
extends Area2D

##########################################################
# Attach this to an Area2D to change the intensity of the
# music while the player is inside the zone.
##########################################################


@export_range(0.0, 1.0, 0.01) var layer1 := 1.0
@export_range(0.0, 1.0, 0.01) var layer2 := 1.0
@export_range(0.0, 1.0, 0.01) var layer3 := 1.0
@export_range(0.0, 1.0, 0.01) var layer4 := 1.0


func _ready() -> void:
	body_entered.connect(_on_body_enter)
	body_exited.connect(_on_body_exit)


func _on_body_enter(body: Node2D) -> void:
	if body is Player:
		AudioManager.push_music_layers([layer1, layer2, layer3, layer4])


func _on_body_exit(body: Node2D) -> void:
	if body is Player:
		AudioManager.pop_music_layers([layer1, layer2, layer3, layer4])
