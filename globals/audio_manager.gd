extends Node

##########################################################
# This is the place for global audio things - changing music or volumes

func set_music(stream_resource) -> void:
	pass

# if we want to do responsive music we can define
# a few intensity levels and map or mix between them here,
# a given music stream resource might define all 3 or only
# 1 of these (e.g. the title music wouldn't have multiple levels)
# e.g. 1=light exploring, 2=mid exploring, 3=enemy encounter
func set_music_intensity(v: int) -> void:
	pass

 
# all of these can be values between 0.0 and 1.0


func get_music_balance() -> float:
	return 1.0


func set_music_balance(v: float) -> void:
	pass

	
func get_sfx_balance() -> float:
	return 1.0


func set_sfx_balance(v: float) -> void:
	pass
