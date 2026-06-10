extends Node

##########################################################
# This is the place for global audio things - changing music or volumes
##########################################################

const MIN_ROOM_SIZE = 0.1
const MAX_ROOM_SIZE = 1.0
const SFX_REVERB_INDEX = 0
const MUSIC_LOW_PASS_INDEX = 0
const MIN_LP_FREQ = 2000
const MAX_LP_FREQ = 20500

var cur_type: String = "wheel"
var cur_intensity := 1
var bus_music: int
var bus_sfx: int
var bus_atmosphere: int

const STREAMS = [
	"exploring-1",
	"exploring-2",
	"exploring-3",
	"wheel-1",
]
var active_streams: Dictionary[String, int] = {}

# NOTE: it's not clear to me whether we should have a single AudioStreamPlayer for
# all music (in the main scene) or one per world. I _think_ we want the former and
# that's where we're starting.

# TODO: add push/pop by name
# TODO: persist the volume settings

func _ready() -> void:
	bus_music = AudioServer.get_bus_index("Music")
	bus_sfx = AudioServer.get_bus_index("SFX")
	bus_atmosphere = AudioServer.get_bus_index("Atmosphere")
	reset_music_damping()
	reset_room_size()


func get_stream_player() -> AudioStreamPlayer:
	var stream_player: AudioStreamPlayer = get_tree().get_first_node_in_group("background_music")
	if not stream_player:
		Log.warn(self, "no audio stream player found")
	return stream_player


# TODO: it'd be nice to validate that a given combination actually exists first
# We could also use an outer AudioStreamInteractive and an inner AudioStreamSynchronized
# to do the intensity levels. Lots of freedom to adjust here based on the music
# people are willing and abel to write.
func set_music(music_type: String, intensity = 1) -> void:
	var stream_player := get_stream_player()
	if not stream_player:
		return

	if music_type == "" or intensity < 1:
		Log.info(self, "stopping music")
		stream_player.stop()
		return

	if not is_valid_music(music_type, intensity):
		Log.warn(self, "invalid music requested", music_type, intensity)
		return

	Log.info(self, "changing music", music_type, "at level", intensity)
	cur_type = music_type
	cur_intensity = intensity
	
	var sync: AudioStreamSynchronized = stream_player.stream
	if sync and sync is AudioStreamSynchronized:
		for i in range(STREAMS.size()):
			sync.set_sync_stream_volume(i, linear_to_db(0.0))
		active_streams = {}
		push_music_intensity(intensity)

	if not stream_player.playing:
		stream_player.play()

	#var playback: AudioStreamPlaybackInteractive = stream_player.get_stream_playback() if stream_player else null
	#if playback and playback is AudioStreamPlaybackInteractive:
		#playback.switch_to_clip_by_name(_get_clip_name(music_type, intensity))


func pause_music() -> void:
	Log.info(self, "music paused")
	get_stream_player().stream_paused = true


func resume_music() -> void:
	Log.info(self, "music resumed")
	get_stream_player().stream_paused = false


func set_room_size(size: float) -> void:
	var sfx_reverb: AudioEffectReverb = AudioServer.get_bus_effect(bus_sfx, SFX_REVERB_INDEX)
	sfx_reverb.room_size = lerpf(MIN_ROOM_SIZE, MAX_ROOM_SIZE, size)


func reset_room_size() -> void:
	set_room_size(0.0)


func set_music_damping(amount: float) -> void:
	var sfx_lp: AudioEffectLowPassFilter = AudioServer.get_bus_effect(bus_music, MUSIC_LOW_PASS_INDEX)
	sfx_lp.cutoff_hz = lerp(MAX_LP_FREQ, MIN_LP_FREQ, amount)


func reset_music_damping() -> void:
	set_music_damping(0.0)


func _get_clip_name(music_type: String, intensity: int) -> String:
	return music_type + "-" + str(intensity)


func is_valid_music(music_type: String, intensity = 1) -> bool:
	return _get_clip_name(music_type, intensity) in STREAMS
	#var stream_player := get_stream_player()
	#if not stream_player:
		#return false
	#var stream: AudioStreamInteractive = stream_player.stream
	#if not stream:
		#return false
	#var clip_name := _get_clip_name(music_type, intensity)
	#for i in range(stream.clip_count):
		#if stream.get_clip_name(i) == clip_name:
			#return true
	#return false


# if we want to do responsive music we can define
# a few intensity levels and map or mix between them here,
# a given music stream resource might define all 3 or only
# 1 of these (e.g. the title music wouldn't have multiple levels)
# e.g. 1=light exploring, 2=mid exploring, 3=enemy encounter
func set_music_intensity(v: int) -> void:
	set_music(cur_type, v)

 
func push_music_intensity(v: int) -> void:
	var clip = _get_clip_name(cur_type, v)
	var idx = STREAMS.find(clip)
	if idx >= 0:
		active_streams.set(clip, active_streams.get(clip, 0) + 1)
		_set_stream_level(idx, 1.0)

func pop_music_intensity(v: int) -> void:
	var clip = _get_clip_name(cur_type, v)
	var idx = STREAMS.find(clip)
	if idx >= 0 and clip in active_streams:
		var new_val: int = max(active_streams.get(clip) - 1, 0)
		active_streams.set(clip, new_val)
		if new_val == 0:
			_set_stream_level(idx, 0.0)

func _set_stream_level(idx: int, linear_volume: float) -> void:
	var stream_player := get_stream_player()
	if not stream_player:
		return
	var sync: AudioStreamSynchronized = stream_player.stream
	if sync and sync is AudioStreamSynchronized:
		sync.set_sync_stream_volume(idx, linear_to_db(linear_volume))


# all of these can be values between 0.0 and 1.0


func get_music_balance() -> float:
	return AudioServer.get_bus_volume_linear(bus_music)


func set_music_balance(v: float) -> void:
	Log.info(self, "setting music balance", v)
	AudioServer.set_bus_volume_linear(bus_music, v)

	
func get_sfx_balance() -> float:
	return AudioServer.get_bus_volume_linear(bus_sfx)


func set_sfx_balance(v: float) -> void:
	Log.info(self, "setting sfx balance", v)
	AudioServer.set_bus_volume_linear(bus_sfx, v)
	AudioServer.set_bus_volume_linear(bus_atmosphere, v)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		AudioServer.set_bus_mute(0, !AudioServer.is_bus_mute(0))
