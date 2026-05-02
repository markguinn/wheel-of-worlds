extends Node

##########################################################
# This is the place for global audio things - changing music or volumes
##########################################################

const BUS_MUSIC = 0
const BUS_SFX = 1
const BUS_ATMOSPHERE = 2

var cur_type: String = "wheel"
var cur_intensity := 1

# NOTE: it's not clear to me whether we should have a single AudioStreamPlayer for
# all music (in the main scene) or one per world. I _think_ we want the former and
# that's where we're starting.

# TODO: it'd be nice to validate that a given combination actually exists first
# We could also use an outer AudioStreamInteractive and an inner AudioStreamSynchronized
# to do the intensity levels. Lots of freedom to adjust here based on the music
# people are willing and abel to write.
func set_music(music_type: String, intensity = 1) -> void:
	Log.info(self, "changing music", music_type, "at level", intensity)
	var player: AudioStreamPlayer = get_tree().get_first_node_in_group("background_music")
	#var stream: AudioStreamInteractive = player.stream if player else null
	var playback = player.get_stream_playback() if player else null
	if playback and playback is AudioStreamPlaybackInteractive:
		playback.switch_to_clip_by_name(music_type + "-" + str(intensity))
	cur_type = music_type
	cur_intensity = intensity


# if we want to do responsive music we can define
# a few intensity levels and map or mix between them here,
# a given music stream resource might define all 3 or only
# 1 of these (e.g. the title music wouldn't have multiple levels)
# e.g. 1=light exploring, 2=mid exploring, 3=enemy encounter
func set_music_intensity(v: int) -> void:
	set_music(cur_type, v)

 
# all of these can be values between 0.0 and 1.0


func get_music_balance() -> float:
	return AudioServer.get_bus_volume_linear(BUS_MUSIC)


func set_music_balance(v: float) -> void:
	AudioServer.set_bus_volume_linear(BUS_MUSIC, v)

	
func get_sfx_balance() -> float:
	return AudioServer.get_bus_volume_linear(BUS_SFX)


func set_sfx_balance(v: float) -> void:
	AudioServer.set_bus_volume_linear(BUS_SFX, v)
	AudioServer.set_bus_volume_linear(BUS_ATMOSPHERE, v)
