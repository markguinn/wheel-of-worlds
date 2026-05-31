class_name OrbSFX
extends Node

func play_bounce(vol = 1.0) -> void:
	var b: AudioStreamPlayer2D = $Bounce
	b.volume_linear = vol
	b.play()
