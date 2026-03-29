class_name PlayerSFX
extends Node2D


func play_footstep() -> void:
	$Footsteps.play()


func play_landing() -> void:
	$Footsteps.play()


func play_jump() -> void:
	$Jump.play()


func play_pick_up() -> void:
	$PickUp.play()


func play_stand_up() -> void:
	$StandUp.play()


func play_ragdoll_impact() -> void:
	$Ouch.play()


func play_tripped() -> void:
	pass
