class_name GeographicLabel
extends FileLabel

@export var visible_area: Area2D
@export var fade_seconds := 0.5

var body_count: int = 0
var tween: Tween


func _ready() -> void:
	super._ready()
	if not visible_area:
		var idx = get_children().find_custom(func(n): return n is Area2D)
		if idx > -1:
			visible_area = get_child(idx)
		elif get_parent() is Area2D:
			visible_area = get_parent()
		else:
			Log.warn(self, "GeographicLabel has no visible area. It will stay permanently visible")
	if visible_area:
		modulate = Color.TRANSPARENT
		visible_area.body_entered.connect(_on_body_entered)
		visible_area.body_exited.connect(_on_body_exited)


func _on_body_entered(_body: Node2D) -> void:
	body_count += 1
	Log.debug(self, "entered", body_count)
	if body_count == 1:
		_show()


func _on_body_exited(_body: Node2D) -> void:
	body_count = max(0, body_count - 1)
	Log.debug(self, "exited", body_count)
	if body_count == 0:
		_hide()


# TODO: zoom/move the camera if not fully visible

func _show() -> Tween:
	if tween and tween.is_running():
		tween.stop()
	tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, fade_seconds)
	return tween


func _hide() -> Tween:
	if tween and tween.is_running():
		tween.stop()
	tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_seconds)
	return tween
