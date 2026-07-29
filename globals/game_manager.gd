extends Node

########################################################
# This is the spot for things that orchestrate game play
# outside of a single stage or screen
########################################################

signal scene_changed

# we can use this to enable/disable logging, cheats, debug visuals, etc
const DEV_MODE = false
const TITLE_SCREEN = "res://screens/title_screen/title_screen.tscn"

var _now := 0

# this will be true when in a stage and false otherwise (title screen, credits, etc)
# it will remain true when paused though
var is_in_game := false


## Returns the parent node for the active screen or stage
func get_container() -> Node2D:
	return get_tree().get_first_node_in_group("scene_container")


## Returns the root of the current active scene
func get_active_scene() -> Node:
	return get_container().get_child(0)


## Returns the currently active player
func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")


## Just like Time.get_ticks_msec except it responds to
## pausing and adjusting Engine.time_scale
func now_ms() -> int:
	return _now


func now_sec() -> float:
	return float(_now) / 1000.0


var last_times: Dictionary[Variant, int] = {}
func rate_limit(min_ms: int, scope: Variant) -> bool:
	if last_times.has(scope) and _now < last_times[scope] + min_ms:
		return true
	last_times[scope] = _now
	return false


func start_new_game() -> void:
	StateManager.reset()
	change_scene("res://stages/seussworld/tutorial.tscn")


func resume_previous_scene() -> void:
	if StateManager.has_key("path", "cur_scene"):
		var path = StateManager.get_key("path", "cur_scene")
		var params = StateManager.get_key("params", "cur_scene", {})
		change_scene(path, params)
	else:
		start_new_game()


var is_changing := false
## Load in a new scene. For playable stages, params can generally have a "target_portal"
## key to indicate where you're coming into the level. Maybe that's the only one we'll
## have. Maybe there will be more. Who knows.
# TODO: can we keep the instances or the loaded scene in memory?
func change_scene(new_scene_path: String, params = {}) -> void:
	if is_changing:
		Log.warn(self, "asked to change to", new_scene_path, "but in the middle of another change")
		return
	is_changing = true
	Log.info(self, "changing to ", new_scene_path, params)
	var fade_in: bool = params.get("fade_in", true)
	var fade_out: bool = params.get("fade_out", true)
	var container := get_container()
	var cur_scene := get_active_scene()

	# start the fade early so we load while it's fading
	var fade_out_tween: Tween
	if fade_out:
		fade_out_tween = VFX.white_out()

	var new_scene: Resource = load(new_scene_path)
	if not new_scene:
		new_scene = load(TITLE_SCREEN)
	var new_instance: Node = new_scene.instantiate()
	if new_instance.get("persist_as_current"):
		StateManager.set_keys.call_deferred({ "path": new_scene_path, "params": params }, "cur_scene")
	
	if fade_out:
		await fade_out_tween.finished
	
	container.add_child(new_instance)
	container.remove_child(cur_scene)
	cur_scene.queue_free()
	var t = get_tree()
	if t:
		await get_tree().physics_frame
	StateManager.manage_scene.call_deferred(new_instance, new_scene_path, params)
	scene_changed.emit.call_deferred()

	if fade_in:
		VFX.white_in()

	is_changing = false


var _hud: CanvasItem
func get_hud() -> CanvasItem:
	if not _hud:
		_hud = get_tree().get_first_node_in_group("hud")
	return _hud


func is_hud_visible() -> bool:
	var hud := get_hud()
	return hud and hud.visible


func hide_hud(immediate = false) -> void:
	var hud := get_hud()
	if hud and hud.visible:
		Log.info(self, "hiding hud")
		if not immediate:
			var t = create_tween()
			t.tween_property(hud, "modulate", Color.TRANSPARENT, 0.2)
			await t.finished
		hud.hide()


func show_hud() -> void:
	var hud := get_hud()
	if hud and not hud.visible:
		Log.info(self, "showing hud")
		hud.modulate = Color.TRANSPARENT
		hud.show()
		var t = create_tween()
		t.tween_property(hud, "modulate", Color.WHITE, 1.5)


func quit_to_title() -> void:
	change_scene(TITLE_SCREEN)
	

func _physics_process(delta: float) -> void:
	_now += roundi(delta * 1000.0)


# This is just for testing. We should remove it before release
#func _input(event: InputEvent) -> void:
	#if GameManager.DEV_MODE and event is InputEventKey and event.pressed and not event.is_echo():
		#match event.physical_keycode:
			#KEY_0:
				#Engine.time_scale = 1.0
			#KEY_9:
				#Engine.time_scale = 0.5
			#KEY_8:
				#Engine.time_scale = 0.25
