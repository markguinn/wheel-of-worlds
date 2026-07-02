extends Node

##########################################################
# This is the place for global audio things - changing music or volumes
##########################################################

const MIN_ROOM_SIZE = 0.1
const MAX_ROOM_SIZE = 1.0
const MIN_REVERB_DAMPING = 0.8
const MAX_REVERB_DAMPING = 0.2
const MIN_REVERB_WET = 0.1
const MAX_REVERB_WET = 0.2
const MIN_REVERB_SPREAD = 0.4
const MAX_REVERB_SPREAD = 1.0
const SFX_REVERB_INDEX = 0
const MUSIC_LOW_PASS_INDEX = 0
const PORTAL_LOW_PASS_INDEX = 0
const MIN_LP_FREQ = 2000
const MAX_LP_FREQ = 20500
const LAYER_TWEEN_TIME = 2.0

var bus_music: int
var bus_sfx: int
var bus_atmosphere: int
var bus_portal: int

var cur_damping := 0.0
var cur_room_size := 0.0

var base_layers: Array[float] = []
var layer_stack: Array[Array] = []
var cur_layers: Array[float] = []
var layer_tween: Tween

# TODO: persist the volume settings


func _ready() -> void:
	bus_music = AudioServer.get_bus_index("Music")
	bus_sfx = AudioServer.get_bus_index("SFX")
	bus_atmosphere = AudioServer.get_bus_index("Atmosphere")
	bus_portal = AudioServer.get_bus_index("Portal")
	reset_music_damping()
	reset_room_size()


func get_stream_player() -> AudioStreamPlayer:
	var stream_player: AudioStreamPlayer = get_tree().get_first_node_in_group("background_music")
	if not stream_player:
		Log.warn(self, "no audio stream player found")
	return stream_player


func get_sync_player() -> AudioStreamSynchronized:
	var stream_player := get_stream_player()
	if stream_player and stream_player.stream is AudioStreamSynchronized:
		return stream_player.stream
	return null


func reset_music() -> void:
	reset_music_damping()
	reset_room_size()
	base_layers = get_music_layers().duplicate()
	Log.info(self, "base music layers", base_layers)
	var p := get_stream_player()
	if p:
		p.play()


func get_music_layers() -> Array[float]:
	var sync: AudioStreamSynchronized = get_sync_player()
	if not sync:
		return []
	cur_layers = []
	for i in range(sync.stream_count):
		cur_layers.append(db_to_linear(sync.get_sync_stream_volume(i)))
	return cur_layers


func set_music_layers(layers: Array[float]) -> void:
	var sync: AudioStreamSynchronized = get_sync_player()
	if not sync:
		return
	for i in range(sync.stream_count):
		if i < layers.size():
			sync.set_sync_stream_volume(i, linear_to_db(layers[i]))
			if i < cur_layers.size():
				cur_layers[i] = layers[i]
	Log.debug(self, "set music layers", layers)


func set_music_layer(linear_vol: float, i: int) -> void:
	var sync: AudioStreamSynchronized = get_sync_player()
	if not sync:
		return
	sync.set_sync_stream_volume(i, linear_to_db(linear_vol))
	if i < cur_layers.size():
		cur_layers[i] = linear_vol


func push_music_layers(layers: Array[float]) -> void:
	Log.info(self, "push layers", layers, layer_stack)
	if not base_layers or base_layers.size() == 0:
		base_layers = get_music_layers()
	if layers.size() <= 0:
		return
	tween_music_layers(layers)
	layer_stack.append(layers)


func tween_music_layers(layers: Array[float]) -> void:
	if layer_tween and layer_tween.is_running():
		layer_tween.stop()
	layer_tween = create_tween()
	cur_layers = get_music_layers()
	layer_tween.tween_method(set_music_layer.bind(0), cur_layers[0], layers[0], LAYER_TWEEN_TIME)
	for i in range(1, layers.size()):
		layer_tween.parallel().tween_method(set_music_layer.bind(i), cur_layers[i], layers[i], LAYER_TWEEN_TIME)


func _same_layers(l1: Array[float], l2: Array[float]) -> bool:
	if l1.size() != l2.size():
		return false
	for i in range(l1.size()):
		if l1[i] != l2[i]:
			return false
	return true


func pop_music_layers(layers: Array[float]) -> void:
	Log.info(self, "pop layers", layers, layer_stack)
	if layers.size() <= 0:
		return
	for i in range(layer_stack.size()):
		var j = layer_stack.size() - 1 - i
		if _same_layers(layers, layer_stack[j]):
			layer_stack.remove_at(j)
			Log.debug(self, "popped layer", j, layer_stack)
			break
	var next_layer = layer_stack.back() if layer_stack.size() > 0 else base_layers
	if not next_layer or next_layer.size() == 0:
		next_layer = [1.0, 0.0, 0.0, 0.0]
	tween_music_layers(next_layer)


func pause_music() -> void:
	var p := get_stream_player()
	if p:
		Log.info(self, "music paused")
		p.stream_paused = true


func resume_music() -> void:
	var p := get_stream_player()
	if p:
		Log.info(self, "music resumed")
		p.stream_paused = false


func get_room_size() -> float:
	return cur_room_size


func set_room_size(size: float) -> void:
	var sfx_reverb: AudioEffectReverb = AudioServer.get_bus_effect(bus_sfx, SFX_REVERB_INDEX)
	sfx_reverb.room_size = lerpf(MIN_ROOM_SIZE, MAX_ROOM_SIZE, size)
	sfx_reverb.damping = lerpf(MIN_REVERB_DAMPING, MAX_REVERB_DAMPING, size)
	sfx_reverb.spread = lerpf(MIN_REVERB_SPREAD, MAX_REVERB_SPREAD, size)
	sfx_reverb.wet = lerpf(MIN_REVERB_WET, MAX_REVERB_WET, size)
	cur_room_size = size


func reset_room_size() -> void:
	set_room_size(0.0)


func get_music_damping() -> float:
	return cur_damping
	
func set_music_damping(amount: float) -> void:
	var sfx_lp: AudioEffectLowPassFilter = AudioServer.get_bus_effect(bus_music, MUSIC_LOW_PASS_INDEX)
	sfx_lp.cutoff_hz = lerp(MAX_LP_FREQ, MIN_LP_FREQ, amount)
	cur_damping = amount


func reset_music_damping() -> void:
	set_music_damping(0.0)


func get_portal_lpf() -> AudioEffectLowPassFilter:
	return AudioServer.get_bus_effect(bus_portal, PORTAL_LOW_PASS_INDEX)


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
