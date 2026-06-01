class_name PlayerSFX
extends Node2D


func play_footstep() -> void:
	$Footsteps.play()


func play_landing() -> void:
	$Footsteps.play()


func play_jump() -> void:
	#$Effort.play()
	pass


func play_push() -> void:
	$Effort.play()


func play_pick_up() -> void:
	$Effort.play()


func play_stand_up() -> void:
	#$Effort.play()
	$Footsteps.play()
	pass


func play_ragdoll_impact() -> void:
	$Ouch.play()


func play_tripped() -> void:
	$Ouch.play()
