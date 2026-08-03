class_name OffscreenOrbIndicator extends Node2D

@export var enabled: bool = true:
	set(v):
		enabled = v
		on_screen_notifier = on_screen_notifier

## Leave false and the indicator will stay hidden until the first time the orb goes off-screen.
@export var apply_immediately: bool = false

@export var rescale_x_with_distance: bool = true

var on_screen_notifier: VisibleOnScreenNotifier2D = null:
	set(v):
		on_screen_notifier = v
		for sig in connected: ## Clear existing connections
			if is_instance_valid(sig):
				if sig.is_connected(visibility_changed): sig.disconnect(visibility_changed)
		connected.clear()
		if v == null: return
		if v is VisibleOnScreenNotifier2D:
			v.screen_entered.connect(visibility_changed.bind(true))
			v.screen_exited.connect(visibility_changed.bind(false))
			if apply_immediately:
				visibility_changed(v.is_on_screen())

var connected: Array[Signal] = []

func _enter_tree() -> void:
	hide()
	modulate = Color.TRANSPARENT

func _process(_delta: float) -> void: 
	if not enabled:
		return
	if not on_screen_notifier:
		return
	if not is_instance_valid(on_screen_notifier):
		return
	
	look_at(on_screen_notifier.global_position)
	if rescale_x_with_distance:
		scale.x = clampf(
			remap(
				global_position.distance_to(on_screen_notifier.global_position),
				2000.0, 12000.0,
				0.75, 6.0
				),
			0.33, 6.0
			)

var _fade_tween: Tween
func visibility_changed(orb_is_visible: bool) -> void:
	if not enabled:
		hide()
		return
	if orb_is_visible:
		if _fade_tween:
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.5)
		_fade_tween.tween_callback(hide)
	else:
		if _fade_tween:
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(self, "modulate", Color.WHITE, 1.5)
		show.call_deferred()
